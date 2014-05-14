//
//  AudioController.h
//  audio
//
//  Created by Hai Le on 26/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

#import "EZAudio.h"

@protocol AudioControllerDelegate;

@interface AudioController : NSObject <EZMicrophoneDelegate>

@property float volume;
@property float lpf;
@property float hpf;
@property float bpf;

@property (nonatomic)       float              highPassGain;
@property (nonatomic)       float              highPassCutOff;
@property (nonatomic)       float              highPassFilterOrder;
@property (nonatomic)       UIColor            *highPassGraphColor;

@property (nonatomic)       float              bandPassGain;
@property (nonatomic)       float              bandPassCutOff;
@property (nonatomic)       float              bandPassBandWidth;
@property (nonatomic)       float              bandPassFilterOrder;
@property (nonatomic)       UIColor            *bandPassGraphColor;

@property (nonatomic)       float              lowPassGain;
@property (nonatomic)       float              lowPassCutOff;
@property (nonatomic)       float              lowPassFilterOrder;
@property (nonatomic)       UIColor            *lowPassGraphColor;

@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,assign) id<AudioControllerDelegate> delegate;

// Singleton methods
+ (AudioController *) sharedInstance;
- (void)resetLowPassFilter;
- (void)resetBandPassFilter;
- (void)resetHighPassFilter;

@end

@protocol AudioControllerDelegate <NSObject>

@optional
- (void)lowPassDidFinish:(float*)data withBufferSize:(UInt32)bufferSize;
- (void)bandPassDidFinish:(float*)data withBufferSize:(UInt32)bufferSize;
- (void)highPassDidFinish:(float*)data withBufferSize:(UInt32)bufferSize;

@end
