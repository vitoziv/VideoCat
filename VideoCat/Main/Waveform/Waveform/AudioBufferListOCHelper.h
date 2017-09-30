//
//  AudioBufferListOCHelper.h
//  VideoCat
//
//  Created by Vito on 30/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

@import AVFoundation;

@interface AudioBufferListOCHelper: NSObject
+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                      numberOfChannels:(UInt32)channels
                                           interleaved:(BOOL)interleaved;
+ (NSArray *)getWaveformDataWithFileRef:(ExtAudioFileRef)fileRef
                            totalFrames:(NSInteger)totalFrames
                               channels:(NSInteger)channels
                            interleaved:(BOOL)interleaved
                         numberOfPoints:(NSInteger)numberOfPoints;
@end
