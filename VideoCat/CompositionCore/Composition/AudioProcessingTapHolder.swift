//
//  AudioProcessingTapHolder.swift
//  VideoCat
//
//  Created by Vito on 2018/5/9.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class AudioProcessingTapHolder {
    var tapInit: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        
        let nonOptionalSelf = clientInfo!.assumingMemoryBound(to: AppDelegate.self).pointee
        
        Log.debug("init \(tap, clientInfo, tapStorageOut, nonOptionalSelf)\n")
        //            tapStorageOut.assignFrom(source:clientInfo, count: 1)
        //            tapStorageOut.init(clientInfo)
    }
    
    var tapFinalize: MTAudioProcessingTapFinalizeCallback = {
        (tap) in
        Log.debug("finalize \(tap)\n")
    }
    
    var tapPrepare: MTAudioProcessingTapPrepareCallback = {
        (tap, b, c) in
        Log.debug("prepare: \(tap, b, c)\n")
    }
    
    var tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
        (tap) in
        Log.debug("unprepare \(tap)\n")
    }
    
    var tapProcess: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        Log.debug("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
        
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        Log.debug("get audio: \(status)\n")
    }
    
    var tap: Unmanaged<MTAudioProcessingTap>?
    
    deinit {
        tap?.release()
    }
    
    init() {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess)
        var tap: Unmanaged<MTAudioProcessingTap>?
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        
        Log.debug("err: \(err)\n")
        if err != noErr {
            Log.debug("Warning: failed to create audioProcessingTap")
        }
        self.tap = tap
    }
}
