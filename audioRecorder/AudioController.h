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

@interface AudioController : NSObject <EZMicrophoneDelegate>

@property float volume;
@property float lpf;
@property float hpf;
@property float bpf;
@property (nonatomic)UIColor *lpGraphColor;
@property (nonatomic)UIColor *hpGraphColor;
@property (nonatomic)UIColor *bpGraphColor;
@property (nonatomic)float lpfFreq1;
@property (nonatomic)float hpfFreq1;
@property (nonatomic)float bpfFreq1;
@property (nonatomic)float bpfFreq2;

@property (nonatomic)float hpNoiseFloor;
@property (nonatomic)float bpNoiseFloor;
@property (nonatomic)float lpNoiseFloor;

@property (nonatomic,strong) EZMicrophone *microphone;

// Singleton methods
+ (AudioController *) sharedInstance;
- (void)saveLPGraphData:(UIColor*)color cutoffFreq:(float)cutoff;

- (void)start;

@end
