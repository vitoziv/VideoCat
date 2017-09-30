//
//  AudioBufferListOCHelper.m
//  VideoCat
//
//  Created by Vito on 30/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

#import "AudioBufferListOCHelper.h"
@import CoreGraphics;

@implementation AudioBufferListOCHelper
+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                      numberOfChannels:(UInt32)channels
                                           interleaved:(BOOL)interleaved
{
    unsigned nBuffers;
    unsigned bufferSize;
    unsigned channelsPerBuffer;
    if (interleaved)
    {
        nBuffers = 1;
        bufferSize = sizeof(float) * frames * channels;
        channelsPerBuffer = channels;
    }
    else
    {
        nBuffers = channels;
        bufferSize = sizeof(float) * frames;
        channelsPerBuffer = 1;
    }
    
    AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (channels-1));
    audioBufferList->mNumberBuffers = nBuffers;
    for(unsigned i = 0; i < nBuffers; i++)
    {
        audioBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
        audioBufferList->mBuffers[i].mDataByteSize = bufferSize;
        audioBufferList->mBuffers[i].mData = calloc(bufferSize, 1);
    }
    return audioBufferList;
}

+ (NSArray *)getWaveformDataWithFileRef:(ExtAudioFileRef)fileRef
                                        totalFrames:(NSInteger)totalFrames
                                            channels:(NSInteger)channels
                                        interleaved:(BOOL)interleaved
                                     numberOfPoints:(NSInteger)numberOfPoints {
    
    float **data = (float **)malloc( sizeof(float*) * channels );
    for (int i = 0; i < channels; i++)
    {
        data[i] = (float *)malloc( sizeof(float) * numberOfPoints );
    }
    
    // seek to 0
    OSStatus status = ExtAudioFileSeek(fileRef, 0);
    if (status != noErr) {
        return @[];
    }
    
    // calculate the required number of frames per buffer
    SInt64 framesPerBuffer = ((SInt64)totalFrames / numberOfPoints);
    SInt64 framesPerChannel = framesPerBuffer / channels;
    
    // allocate an audio buffer list
    AudioBufferList *audioBufferList = [self audioBufferListWithNumberOfFrames:(UInt32)framesPerBuffer
                                                              numberOfChannels:(UInt32)channels
                                                                   interleaved:interleaved];
    
    // read through file and calculate rms at each point
    for (SInt64 i = 0; i < numberOfPoints; i++)
    {
        UInt32 bufferSize = (UInt32) framesPerBuffer;
        OSStatus status = ExtAudioFileRead(fileRef, &bufferSize, audioBufferList);
        if (status != noErr) {
            return @[];
        }
        if (interleaved)
        {
            float *buffer = (float *)audioBufferList->mBuffers[0].mData;
            for (int channel = 0; channel < channels; channel++)
            {
                float channelData[framesPerChannel];
                for (int frame = 0; frame < framesPerChannel; frame++)
                {
                    channelData[frame] = buffer[frame * channels + channel];
                }
                float rms = [self RMS:channelData length:(UInt32)framesPerChannel];
                data[channel][i] = rms;
            }
        }
        else
        {
            for (int channel = 0; channel < channels; channel++)
            {
                float *channelData = audioBufferList->mBuffers[channel].mData;
                float rms = [self RMS:channelData length:bufferSize];
                data[channel][i] = rms;
            }
        }
    }
    
    // clean up
    [self freeBufferList:audioBufferList];
    
    // Save to array
    NSMutableArray *pointsData = [NSMutableArray array];
    for (NSInteger i = 0; i < channels; i++) {
        NSMutableArray *channelData = [NSMutableArray array];
        for (NSInteger pointIndex = 0; pointIndex < numberOfPoints; pointIndex++) {
            float point = data[i][pointIndex];
            [channelData addObject:@(point)];
        }
        [pointsData addObject:channelData];
    }
    
    // cleanup
    for (int i = 0; i < channels; i++) {
        free(data[i]);
    }
    free(data);
    
    return pointsData;
}

+ (float)RMS:(float *)buffer length:(int)bufferSize {
    float sum = 0.0;
    for(int i = 0; i < bufferSize; i++)
        sum += buffer[i] * buffer[i];
    return sqrtf( sum / bufferSize);
}

+ (void)freeBufferList:(AudioBufferList *)bufferList {
    if (bufferList) {
        if (bufferList->mNumberBuffers) {
            for( int i = 0; i < bufferList->mNumberBuffers; i++) {
                if (bufferList->mBuffers[i].mData) {
                    free(bufferList->mBuffers[i].mData);
                }
            }
        }
        free(bufferList);
    }
    bufferList = NULL;
}


@end
