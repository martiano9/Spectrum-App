//
//  AudioController.m
//  audio
//
//  Created by Hai Le on 26/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AudioController.h"
#import "Configs.h"
#include <stdio.h>
#import "Dsp.h"

using namespace Dsp;

#define absX(x) (x<0?0-x:x)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)))
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-50.0)

static AudioController *sharedInstance = nil;

@interface AudioController () {
    __block float dbVal;
    
    SimpleFilter<Butterworth::LowPass<10>,1> lowpass;
    SimpleFilter<Butterworth::BandPass<10>,1> bandpass;
    SimpleFilter<Butterworth::HighPass<10>,1> highpass;
    
    float *tempDataLP;
    float *tempDataBP;
    float *tempDataHP;
}

@end

@implementation AudioController

@synthesize volume;
@synthesize lpf;
@synthesize hpf;
@synthesize bpf;

@synthesize highPassGain            = _highPassGain;
@synthesize highPassCutOff          = _highPassCutOff;
@synthesize highPassFilterOrder     = _highPassFilterOrder;
@synthesize highPassGraphColor      = _highPassGraphColor;

@synthesize bandPassGain            = _bandPassGain;
@synthesize bandPassBandWidth       = _bandPassBandWidth;
@synthesize bandPassCutOff          = _bandPassCutOff;
@synthesize bandPassFilterOrder     = _bandPassFilterOrder;
@synthesize bandPassGraphColor      = _bandPassGraphColor;

@synthesize lowPassGain             = _lowPassGain;
@synthesize lowPassCutOff           = _lowPassCutOff;
@synthesize lowPassFilterOrder      = _lowPassFilterOrder;
@synthesize lowPassGraphColor       = _lowPassGraphColor;

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
        
        if (self.highPassFilterOrder    == 0.0) self.highPassFilterOrder = dFilterOrder;
        if (self.highPassCutOff         == 0.0) self.highPassCutOff = dHighPassCutOff;
        if (self.highPassGain           == 0.0) self.highPassGain = noiseFloorDefaultValue;
        if (self.highPassGraphColor     == nil)
            self.highPassGraphColor = [UIColor colorWithRed:0.99 green:0.96 blue:0 alpha:1];
        [self resetHighPassFilter];
        
        if (self.bandPassFilterOrder    == 0.0) self.bandPassFilterOrder = dFilterOrder;
        if (self.bandPassBandWidth      == 0.0) self.bandPassBandWidth = dBandPassBandWidth;
        if (self.bandPassCutOff         == 0.0) self.bandPassCutOff = dBandPassCutOff;
        if (self.bandPassGain           == 0.0) self.bandPassGain = noiseFloorDefaultValue;
        if (self.bandPassGraphColor     == nil)
            self.bandPassGraphColor = [UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:0.8];
        [self resetBandPassFilter];
        
        if (self.lowPassFilterOrder     == 0.0) self.lowPassFilterOrder = dFilterOrder;
        if (self.lowPassCutOff          == 0.0) self.lowPassCutOff = dLowPassCutOff;
        if (self.lowPassGain            == 0.0) self.lowPassGain = noiseFloorDefaultValue;
        if (self.lowPassGraphColor      == nil)
            self.lowPassGraphColor = [UIColor colorWithRed:0.27 green:0.58 blue:0.84 alpha:1];
        [self resetLowPassFilter];
        
        tempDataLP = new float[512];
        tempDataBP = new float[512];
        tempDataHP = new float[512];
        
        self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
    }
    return self;
}

#pragma mark - Override Getters Setters
//
// High-pass Filter
//
- (void)setHighPassGain:(float)highPassGain {
    _highPassGain = highPassGain;
    [self saveFloat:highPassGain forKey:kHighPassGain];
}

- (float)highPassGain {
    if (_highPassGain == 0.0) {
        _highPassGain = [self floatForKey:kHighPassGain];
    }
    return _highPassGain;
}

- (void)setHighPassCutOff:(float)highPassCutOff {
    _highPassCutOff = highPassCutOff;
    
    [self saveFloat:highPassCutOff forKey:kHighPassCutOff];
}

- (float)highPassCutOff {
    if (_highPassCutOff == 0.0) {
        _highPassCutOff = [self floatForKey:kHighPassCutOff];
    }
    return _highPassCutOff;
}

- (void)setHighPassFilterOrder:(float)highPassFilterOrder {
    _highPassFilterOrder = highPassFilterOrder;
    
    [self saveFloat:highPassFilterOrder forKey:kHighPassFilterOrder];
}

- (float)highPassFilterOrder {
    if (_highPassFilterOrder == 0.0) {
        _highPassFilterOrder = [self floatForKey:kHighPassFilterOrder];
    }
    return _highPassFilterOrder;
}

- (void)setHighPassGraphColor:(UIColor *)highPassGraphColor {
    _highPassGraphColor = highPassGraphColor;
    
    [self saveColor:highPassGraphColor forKey:kHighPassGraphColor];
}

- (UIColor *)highPassGraphColor {
    if (_highPassGraphColor == nil) {
        _highPassGraphColor = [self colorForKey:kHighPassGraphColor];
    }
    return _highPassGraphColor;
}

//
// Band-pass Filter
//
- (void)setBandPassGain:(float)bandPassGain {
    _bandPassGain = bandPassGain;
    [self saveFloat:bandPassGain forKey:kBandPassGain];
}

- (float)bandPassGain {
    if (_bandPassGain == 0.0) {
        _bandPassGain = [self floatForKey:kBandPassGain];
    }
    return _bandPassGain;
}

- (void)setBandPassCutOff:(float)bandPassCutOff {
    _bandPassCutOff = bandPassCutOff;
    
    [self saveFloat:bandPassCutOff forKey:kBandPassCutOff];
}

- (float)bandPassCutOff {
    if (_bandPassCutOff == 0.0) {
        _bandPassCutOff = [self floatForKey:kBandPassCutOff];
    }
    return _bandPassCutOff;
}

- (void)setBandPassBandWidth:(float)bandPassBandWidth {
    _bandPassBandWidth = bandPassBandWidth;
    
    [self saveFloat:bandPassBandWidth forKey:kBandPassBandWidth];
}

- (float)bandPassBandWidth {
    if (_bandPassBandWidth == 0.0) {
        _bandPassBandWidth = [self floatForKey:kBandPassBandWidth];
    }
    return _bandPassBandWidth;
}

- (void)setBandPassFilterOrder:(float)bandPassFilterOrder {
    _bandPassFilterOrder = bandPassFilterOrder;
    
    [self saveFloat:bandPassFilterOrder forKey:kBandPassFilterOrder];
}

- (float)bandPassFilterOrder {
    if (_bandPassFilterOrder == 0.0) {
        _bandPassFilterOrder = [self floatForKey:kBandPassFilterOrder];
    }
    return _bandPassFilterOrder;
}

- (void)setBandPassGraphColor:(UIColor *)bandPassGraphColor {
    _bandPassGraphColor = bandPassGraphColor;
    
    [self saveColor:bandPassGraphColor forKey:kBandPassGraphColor];
}

- (UIColor *)bandPassGraphColor {
    if (_bandPassGraphColor == nil) {
        _bandPassGraphColor = [self colorForKey:kBandPassGraphColor];
    }
    return _bandPassGraphColor;
}

//
// Low-pass Filter
//
- (void)setLowPassGain:(float)lowPassGain {
    _lowPassGain = lowPassGain;
    [self saveFloat:lowPassGain forKey:kLowPassGain];
}

- (float)lowPassGain {
    if (_lowPassGain == 0.0) {
        _lowPassGain = [self floatForKey:kLowPassGain];
    }
    return _lowPassGain;
}

- (void)setLowPassCutOff:(float)lowPassCutOff {
    _lowPassCutOff = lowPassCutOff;
    
    [self saveFloat:_lowPassCutOff forKey:kLowPassCutOff];
}

- (float)lowPassCutOff {
    if (_lowPassCutOff == 0.0) {
        _lowPassCutOff = [self floatForKey:kLowPassCutOff];
    }
    return _lowPassCutOff;
}

- (void)setLowPassFilterOrder:(float)lowPassFilterOrder {
    _lowPassFilterOrder = lowPassFilterOrder;
    
    [self saveFloat:lowPassFilterOrder forKey:kLowPassFilterOrder];
}

- (float)lowPassFilterOrder {
    if (_lowPassFilterOrder == 0.0) {
        _lowPassFilterOrder = [self floatForKey:kLowPassFilterOrder];
    }
    return _lowPassFilterOrder;
}

- (void)setLowPassGraphColor:(UIColor *)lowPassGraphColor {
    _lowPassGraphColor = lowPassGraphColor;
    
    [self saveColor:lowPassGraphColor forKey:kLowPassGraphColor];
}

- (UIColor *)lowPassGraphColor {
    if (_lowPassGraphColor == nil) {
        _lowPassGraphColor = [self colorForKey:kLowPassGraphColor];
    }
    return _lowPassGraphColor;
}

#pragma mark - EZMicrophoneDelegate

-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    dispatch_async(dispatch_get_main_queue(),^{
        lpf = 0;
        hpf = 0;
        bpf = 0;
        
        // Low pass
        copy(bufferSize, tempDataLP, buffer[0]);
        lowpass.process(bufferSize, &tempDataLP);
        if([self.delegate respondsToSelector:@selector(lowPassDidFinish:withBufferSize:)]) {
            [self.delegate lowPassDidFinish:tempDataLP withBufferSize:bufferSize];
        }
        lpf = [EZAudio average:tempDataLP length:bufferSize];
        lpf = decibel(lpf/bufferSize) + self.lowPassGain*10;
        lpf = lpf < 0 ? 0 : lpf;
        
        // High pass
        copy(bufferSize, tempDataHP, buffer[0]);
        highpass.process(bufferSize, &tempDataHP);
        if([self.delegate respondsToSelector:@selector(highPassDidFinish:withBufferSize:)]) {
            [self.delegate highPassDidFinish:tempDataHP withBufferSize:bufferSize];
        }
        hpf = [EZAudio average:tempDataHP length:bufferSize];
        hpf = decibel(hpf/bufferSize) + self.highPassGain*10;
        hpf = hpf < 0 ? 0 : hpf;
        
        // Band pass
        copy(bufferSize, tempDataBP, buffer[0]);
        bandpass.process(bufferSize, &tempDataBP);
        if([self.delegate respondsToSelector:@selector(bandPassDidFinish:withBufferSize:)]) {
            [self.delegate bandPassDidFinish:tempDataBP withBufferSize:bufferSize];
        }
        bpf = [EZAudio average:tempDataBP length:bufferSize];
        bpf = decibel(bpf/bufferSize) + self.bandPassGain*10;
        bpf = bpf < 0 ? 0 : bpf;
        
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

#pragma mark - Public Category

- (void)resetBandPassFilter {
    bandpass.setup(_bandPassFilterOrder, 44100, _bandPassCutOff, _bandPassBandWidth);
    bandpass.reset();
}

- (void)resetHighPassFilter {
    highpass.setup(_highPassFilterOrder, 44100, _highPassCutOff);
    highpass.reset();
}

- (void)resetLowPassFilter {
    lowpass.setup(_lowPassFilterOrder, 44100, _lowPassCutOff);
    lowpass.reset();
}

#pragma mark - Private Category

- (void)saveFloat:(float)value forKey:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:value] forKey:key];
    [defaults synchronize];
}

- (float)floatForKey:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:key]floatValue];
}

- (void)saveColor:(UIColor*)color forKey:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:key];
    [defaults synchronize];
}

- (UIColor*)colorForKey:(NSString*)key {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return (UIColor*)[NSKeyedUnarchiver unarchiveObjectWithData:colorData];
}

@end
