//
//  AudioSampleOperation.swift
//  VideoCat
//
//  Created by Vito on 09/10/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

class AudioSampleOperation {
    
    /// How many point will display on the screen for per second audio data
    var widthPerSecond: CGFloat = 10
    
    private var filter: [Float] = []
    private var samplesPerPixel: Int = 0 {
        didSet {
            self.filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        }
    }
    private(set) var outputSamples = [CGFloat]()
    private(set) var sampleMax: CGFloat = 0
    
    private var sampleBuffer = Data()
    
    
    init(widthPerSecond: CGFloat) {
        self.widthPerSecond = widthPerSecond
    }
    
    func loadSamples(from asset: AVAsset) throws {
        guard
            let assetTrack = asset.tracks(withMediaType: .audio).first,
            let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
            let audioFormatDesc = formatDescriptions.first,
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
            else {
                throw NSError(domain: "com.sampleoperation",
                              code: 0,
                              userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Can't load asset", comment: "")])
        }
        
        samplesPerPixel = Int(asbd.pointee.mSampleRate * Double(asbd.pointee.mChannelsPerFrame) / Double(widthPerSecond))
        
        let reader = try AVAssetReader(asset: asset)
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
                throw NSError(domain: "com.sampleoperation",
                              code: 0,
                              userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Wrong format description", comment: "")])
            }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() } // Cancel reading if we exit early if operation is cancelled
        
        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer() else {
                break
            }
            // Append audio sample buffer into our current sample buffer
            appendSampleBuffer(readSampleBuffer)
            CMSampleBufferInvalidate(readSampleBuffer)
        }
        
        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        processRemaining()
        
        if reader.status != .completed {
            print("LVWaveformView failed to read audio: \(String(describing: reader.error))")
            throw reader.error ?? NSError(domain: "com.sampleoperation",
                                          code: 0,
                                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Unknown error", comment: "")])
        }
    }
    
    func appendSampleBuffer(_ readSampleBuffer: CMSampleBuffer) {
        guard let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else { return }
        var readBufferLength = 0
        var readBufferPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(readBuffer, 0, &readBufferLength, nil, &readBufferPointer)
        sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
        
        let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
        let downSampledLength = totalSamples / samplesPerPixel
        let samplesToProcess = downSampledLength * samplesPerPixel
        
        guard samplesToProcess > 0 else { return }
        
        processSamples(fromData: &sampleBuffer,
                       sampleMax: &sampleMax,
                       outputSamples: &outputSamples,
                       samplesToProcess: samplesToProcess,
                       downSampledLength: downSampledLength,
                       samplesPerPixel: samplesPerPixel,
                       filter: filter)
    }
    
    func processRemaining() {
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            
            processSamples(fromData: &sampleBuffer,
                           sampleMax: &sampleMax,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
    }
    
    fileprivate func processSamples(fromData sampleBuffer: inout Data, sampleMax: inout CGFloat, outputSamples: inout [CGFloat], samplesToProcess: Int, downSampledLength: Int, samplesPerPixel: Int, filter: [Float]) {
        sampleBuffer.withUnsafeBytes { (samples: UnsafePointer<Int16>) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            let downSampledDataCG = downSampledData.map { (value: Float) -> CGFloat in
                let element = CGFloat(value)
                if element > sampleMax { sampleMax = element }
                return element
            }
            
            // Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            
            outputSamples += downSampledDataCG
        }
    }
    
}

