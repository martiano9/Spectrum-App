//
//  AudioController.m
//  audio
//
//  Created by Hai Le on 26/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AudioController.h"
#import "FilterEquation.h"
#import "Configs.h"
#import "Biquad.h"
#include <stdio.h>
#import "Dsp.h"

#define absX(x) (x<0?0-x:x)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)))
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-50.0)

static AudioController *sharedInstance = nil;

@interface AudioController () {
    __block float dbVal;
    
    FilterEquation *_lowpass;
    FilterEquation *_highpass;
    FilterEquation *_bandpass;
}

@end

@implementation AudioController

@synthesize volume;
@synthesize lpf;
@synthesize hpf;
@synthesize bpf;
@synthesize lpGraphColor = _lpGraphColor;
@synthesize hpGraphColor = _hpGraphColor;
@synthesize bpGraphColor = _bpGraphColor;
@synthesize lpfFreq1 = _lpfFreq1;
@synthesize hpfFreq1 = _hpfFreq1;
@synthesize bpfFreq1 = _bpfFreq1;
@synthesize bpfFreq2 = _bpfFreq2;
@synthesize hpNoiseFloor = _hpNoiseFloor;
@synthesize bpNoiseFloor = _bpNoiseFloor;
@synthesize lpNoiseFloor = _lpNoiseFloor;

#pragma mark - Singleton

+ (AudioController*) sharedInstance
{
	@synchronized(self)
	{
		if (sharedInstance == nil) {
			sharedInstance = [[AudioController alloc] init];
		}
	}
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        
        
        self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
        
        if (self.lpfFreq1 == 0.0) self.lpfFreq1 = 100;
        _lowpass = [[FilterEquation alloc] initLowPass:ButterWorth sampleRate:44100 cutoffFrequency:self.lpfFreq1 order:2];
        
        if (self.hpfFreq1 == 0.0) self.hpfFreq1 = 100;
        _highpass = [[FilterEquation alloc] initHighPass:ButterWorth sampleRate:44100 cutoffFrequency:self.hpfFreq1 order:2];
        
        if (self.bpfFreq1 == 0.0) self.bpfFreq1 = 1000;
        if (self.bpfFreq2 == 0.0) self.bpfFreq2 = 100;
        _bandpass = [[FilterEquation alloc] initBandPass:ButterWorth sampleRate:44100 centerFrequency:self.bpfFreq1 bandWidth:self.bpfFreq2 order:2];
        
    }
    return self;
}

- (void)start {
    
}

- (void)saveLPGraphData:(UIColor*)color cutoffFreq:(float)cutoff {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:color forKey:@"ZColor"];
    
    [defaults synchronize];
}

#pragma mark - Override Getters Setters

- (void)setLpGraphColor:(UIColor *)lpGraphColor {
    _lpGraphColor = lpGraphColor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_lpGraphColor];
    [defaults setObject:colorData forKey:lpfGraphColorKey];
    [defaults synchronize];
}

- (UIColor *)lpGraphColor {
    if (_lpGraphColor == nil) {
        // Load xcolor
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:lpfGraphColorKey];
        _lpGraphColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    }
    
    return _lpGraphColor;
}

- (void)setHpGraphColor:(UIColor *)hpGraphColor {
    _hpGraphColor = hpGraphColor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_hpGraphColor];
    [defaults setObject:colorData forKey:hpfGraphColorKey];
    [defaults synchronize];
}

- (UIColor *)hpGraphColor {
    if (_hpGraphColor == nil) {
        // Load xcolor
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:hpfGraphColorKey];
        _hpGraphColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    }
    
    return _hpGraphColor;
}

- (void)setBpGraphColor:(UIColor *)bpGraphColor {
    _bpGraphColor = bpGraphColor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_bpGraphColor];
    [defaults setObject:colorData forKey:bpfGraphColorKey];
    [defaults synchronize];
}

- (UIColor *)bpGraphColor {
    if (_bpGraphColor == nil) {
        // Load xcolor
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:bpfGraphColorKey];
        _bpGraphColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    }
    
    return _bpGraphColor;
}

- (void)setLpfFreq1:(float)lpfCutoff {
    _lpfFreq1 = lpfCutoff;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_lpfFreq1] forKey:lpfCutoffKey];
    [defaults synchronize];
    
    _lowpass.freq1 = _lpfFreq1;
}

- (float)lpfFreq1 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _lpfFreq1 = [[defaults objectForKey:lpfCutoffKey]floatValue];//value=0
    
    return _lpfFreq1;
}

- (void)setHpfFreq1:(float)hpfCutoff {
    _hpfFreq1 = hpfCutoff;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_hpfFreq1] forKey:hpfCutoffKey];
    [defaults synchronize];
    
    _highpass.freq1 = _hpfFreq1;
}

- (float)hpfFreq1 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _hpfFreq1 = [[defaults objectForKey:hpfCutoffKey]floatValue];//value=0
    
    return _hpfFreq1;
}

- (void)setBpfFreq1:(float)bpfCutoff {
    _bpfFreq1 = bpfCutoff;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_bpfFreq1] forKey:bpfCutoffKey];
    [defaults synchronize];
    
    _bandpass.freq1 = _bpfFreq1;
}

- (float)bpfFreq1 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _bpfFreq1 = [[defaults objectForKey:bpfCutoffKey]floatValue];//value=0
    
    return _bpfFreq1;
}

- (void)setBpfFreq2:(float)bpfCutoff {
    _bpfFreq2 = bpfCutoff;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_bpfFreq2] forKey:bpfBWKey];
    [defaults synchronize];
    
    _bandpass.freq2 = _bpfFreq2;
}

- (float)bpfFreq2 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _bpfFreq2 = [[defaults objectForKey:bpfBWKey]floatValue];//value=0
    
    return _bpfFreq2;
}

- (void)setHpNoiseFloor:(float)hpNoiseFloor {
    _hpNoiseFloor = hpNoiseFloor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_hpNoiseFloor] forKey:hpNoiseFloorKey];
    [defaults synchronize];
}

- (float)hpNoiseFloor {
    if (_hpNoiseFloor == 0) {
        self.hpNoiseFloor = noiseFloorDefaultValue;
    }
    return _hpNoiseFloor;
}

- (void)setBpNoiseFloor:(float)bpNoiseFloor {
    _bpNoiseFloor = bpNoiseFloor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_bpNoiseFloor] forKey:bpNoiseFloorKey];
    [defaults synchronize];
}

- (float)bpNoiseFloor {
    if (_bpNoiseFloor == 0) {
        self.bpNoiseFloor = noiseFloorDefaultValue;
    }
    return _bpNoiseFloor;
}

- (void)setLpNoiseFloor:(float)lpNoiseFloor {
    _lpNoiseFloor = lpNoiseFloor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:_lpNoiseFloor] forKey:bpNoiseFloorKey];
    [defaults synchronize];
}

- (float)lpNoiseFloor {
    if (_lpNoiseFloor == 0) {
        self.lpNoiseFloor = noiseFloorDefaultValue;
    }
    return _lpNoiseFloor;
}

#pragma mark - EZMicrophoneDelegate

-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    dispatch_async(dispatch_get_main_queue(),^{
//        vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
//        float meanVal = 0.0;
//        vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
//
//        float one = 1.0;
//        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
//        dbVal = dbVal + 0.2*(meanVal - dbVal);
//        printf("Decibel level: %f\n", dbVal);
        
        // New code
        lpf = 0;
        hpf = 0;
        bpf = 0;
        
        for (int i = 0; i<bufferSize; i++) {
            lpf += fabsf([_lowpass calculate:buffer[0][i]]);
            
            hpf += fabsf([_highpass calculate:buffer[0][i]]);
            
            bpf += fabsf([_bandpass calculate:buffer[0][i]]);
            
        }
        lpf = decibel(lpf/bufferSize) + 60;
        lpf = lpf < 0 ? 0 : lpf;
        
        hpf = decibel(hpf/bufferSize) + self.hpNoiseFloor;
        hpf = hpf < 0 ? 0 : hpf;
        
        bpf = decibel(bpf/bufferSize) + 60;
        bpf = bpf < 0 ? 0 : bpf;
        
//        float amplitude = [EZAudio average:buffer[0] length:bufferSize];
//        lpf = [_lowpass calculate:amplitude];
//        lpf = decibel(lpf) + 50;
//        lpf = lpf < 0 ? 0 : lpf;
//        
//        hpf = [_highpass calculate:amplitude];
//        hpf = decibel(hpf) + 50;
//        hpf = hpf < 0 ? 0 : hpf;
//        
//        bpf = [_bandpass calculate:amplitude];
//        bpf = decibel(bpf) + 50;
//        bpf = bpf < 0 ? 0 : bpf;
        
    });
}

-(void)microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
    [EZAudio printASBD:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder or EZOutput. Say whattt...
}


@end
