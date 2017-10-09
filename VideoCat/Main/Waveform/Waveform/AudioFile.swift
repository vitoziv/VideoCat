//
//  AudioFile.swift
//  VideoCat
//
//  Created by Vito on 30/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation
import AVFoundation

struct AudioFileInfo {
    var fileRef: ExtAudioFileRef?
}

class AudioFile {
    
    var url: URL
    private var fileInfo = AudioFileInfo()
    private(set) var audioFile: AVAudioFile
    
    init(url: URL) throws {
        self.url = url
        try audioFile = AVAudioFile(forReading: url)
        var status = ExtAudioFileOpenURL(url as CFURL, &fileInfo.fileRef)
        if status != noErr {
            throw NSError(domain: "com.audiofile", code: 0, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Can't open file for url '\(url)'", comment: "")])
        }
//        var clientFormat = defaultAudioFormat()
//        let size = MemoryLayout<AudioStreamBasicDescription>.stride
//        status = ExtAudioFileSetProperty(fileInfo.fileRef!, kExtAudioFileProperty_ClientDataFormat, UInt32(size), &clientFormat)
//        if status != noErr {
//            throw NSError(domain: "com.audiofile", code: 0, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Can't set absd description", comment: "")])
//        }
    }
    
    func getWaveformData(pointsCount: Int) -> [[Float]] {
        guard let fileRef = fileInfo.fileRef else {
            return []
        }

        let status = ExtAudioFileSeek(fileRef, 0)
        if status != noErr {
            return []
        }

        let channelCount = audioFile.fileFormat.channelCount
        let framesPerBuffer = audioFile.length / Int64(pointsCount)
        let framesPerChannel = framesPerBuffer / Int64(audioFile.fileFormat.channelCount)
        let isInterleaved = audioFile.fileFormat.isInterleaved

        let audioBufferList = createAudioBufferList(frameCount: Int(framesPerBuffer), channelCount: channelCount, isInterleaved: isInterleaved)
        var data: [[Float]] = {
            var data: [[Float]] = []
            for _ in 0..<channelCount {
                data.append([])
            }
            return data
        }()

        var bufferSize = UInt32(framesPerBuffer)
        for _ in 0..<pointsCount {
            let status = ExtAudioFileRead(fileRef, &bufferSize, audioBufferList.unsafeMutablePointer)
            if status != noErr {
                return []
            }

            if isInterleaved {
                if let buffer = audioBufferList[0].mData?.assumingMemoryBound(to: Float.self) {
                    for channel in 0..<channelCount {
                        var rms: Float = 0
                        for frame in 0..<framesPerChannel {
                            rms += buffer[Int(frame) * Int(channelCount) + Int(channel)]
                        }
                        rms = rms / Float(framesPerChannel)
                        data[Int(channel)].append(rms)
                    }
                }
            } else {
                for channel in 0..<Int(channelCount) {
                    let buffer = audioBufferList[channel]
                    if let channelData = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        var rms: Float = 0
                        for i in 0..<Int(buffer.mDataByteSize) {
                            rms += channelData[i]
                        }
                        rms = rms / Float(buffer.mDataByteSize)
                        data[Int(channel)].append(rms)
                    }
                }
            }
        }

        for i in 0..<audioBufferList.count {
            free(audioBufferList[i].mData)
        }
        free(audioBufferList.unsafeMutablePointer)

        return data
    }
    
    private func createAudioBufferList(frameCount: Int, channelCount: UInt32, isInterleaved: Bool) -> UnsafeMutableAudioBufferListPointer {
        var nbuffers: Int = 0
        var bufferSize: Int = 0
        var channelsPerBuffer: UInt32 = 0
        
        if isInterleaved {
            nbuffers = 1
            bufferSize = MemoryLayout<Float>.stride * frameCount * Int(channelCount)
            channelsPerBuffer = channelCount
        } else {
            nbuffers = Int(channelCount)
            bufferSize = MemoryLayout<Float>.stride * frameCount
            channelsPerBuffer = 1
        }
        
        let audioBufferList = AudioBufferList.allocate(maximumBuffers: nbuffers)
        for i in 0..<nbuffers {
            audioBufferList[i].mData = calloc(bufferSize, 1)
            audioBufferList[i].mDataByteSize = UInt32(bufferSize)
            audioBufferList[i].mNumberChannels = channelsPerBuffer
        }
        
        return audioBufferList
    }
    
    private func defaultAudioFormat() -> AudioStreamBasicDescription {
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = 44100.0
        asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved
        asbd.mFormatID = kAudioFormatLinearPCM
        let floatByteSize = MemoryLayout<Float>.stride
        asbd.mBitsPerChannel = UInt32(floatByteSize) * 8
        asbd.mBytesPerFrame = UInt32(floatByteSize)
        asbd.mChannelsPerFrame = 2
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame
        return asbd
    }
    
}

/// Helpful additions for using AVAudioFiles within AudioKit
extension AVAudioFile {
    
    // MARK: - Public Properties
    
    /// The number of samples can be accessed by .length property,
    /// but samplesCount has a less ambiguous meaning
    open var samplesCount: Int64 {
        return length
    }
    
    /// strange that sampleRate is a Double and not an Integer
    open var sampleRate: Double {
        return fileFormat.sampleRate
    }
    /// Number of channels, 1 for mono, 2 for stereo
    open var channelCount: UInt32 {
        return fileFormat.channelCount
    }
    
    /// Duration in seconds
    open var duration: Double {
        return Double(samplesCount) / (sampleRate)
    }
    
    /// true if Audio Samples are interleaved
    open var interleaved: Bool {
        return fileFormat.isInterleaved
    }
    
    /// true only if file format is "deinterleaved native-endian float (AVAudioPCMFormatFloat32)"
    open var standard: Bool {
        return fileFormat.isStandard
    }
    
    /// Human-readable version of common format
    open var commonFormatString: String {
        return "\(fileFormat.commonFormat)"
    }
    
    /// the directory path as a URL object
    open var directoryPath: URL {
        return url.deletingLastPathComponent()
    }
    
    /// the file name with extension as a String
    open var fileNamePlusExtension: String {
        return url.lastPathComponent
    }
    
    /// the file name without extension as a String
    open var fileName: String {
        return url.deletingPathExtension().lastPathComponent
    }
    
    /// the file extension as a String (without ".")
    open var fileExt: String {
        return url.pathExtension
    }
    
    override open var description: String {
        return super.description + "\n" + String(describing: fileFormat)
    }
    
    /// returns file Mime Type if exists
    /// Otherwise, returns nil
    /// (useful when sending an AKAudioFile by email)
    public var mimeType: String? {
        switch fileExt.lowercased() {
        case "wav":
            return "audio/wav"
        case "caf":
            return "audio/x-caf"
        case "aif", "aiff", "aifc":
            return "audio/aiff"
        case "m4r":
            return "audio/x-m4r"
        case "m4a":
            return "audio/x-m4a"
        case "mp4":
            return "audio/mp4"
        case "m2a", "mp2":
            return "audio/mpeg"
        case "aac":
            return "audio/aac"
        case "mp3":
            return "audio/mpeg3"
        default:
            return nil
        }
    }
    
}
