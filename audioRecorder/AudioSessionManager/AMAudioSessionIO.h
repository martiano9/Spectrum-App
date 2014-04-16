//
//  AudioSessionManager.h
//  audio
//
//  Created by Hai Le on 8/1/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioManager.h"

@interface AMAudioSessionIO : NSObject {
    AMAudioUnitGraph *_graph;
}

@property (readonly)            bool                        inputDeviceAvailable;
@property (readonly)            NSInteger                   inputNumberOfChannels;
@property (readonly)            Float64                     bufferDuration;
@property (readwrite)           Float64                     graphSampleRate;
@property (readonly)            BOOL                        isRecording;
@property  int takein;
@property  int takeout;
@property float volume;
@property float lpf;
@property float hpf;
@property float bpf;

// Singleton methods
+ (AMAudioSessionIO *) sharedInstance;

- (void)startRecording;
- (void)stopRecording;

@end

