//
//  AMAudioUnitNode.h
//  audio
//
//  Created by Hai Le on 10/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AMAudioUnitGraph;
@class AMDCRejectionFilter;

typedef enum {
    /** Converters */
    AMAudioComponentTypeConverter,
    AMAudioComponentTypeVariSpeed,
    AMAudioComponentTypeiPodTime,
    AMAudioComponentTypeiPodTimeOther,
    
    /** Effects */
    AMAudioComponentTypePeakLimiter,
    AMAudioComponentTypeDynamicsProcessor,
    AMAudioComponentTypeReverb2,
    AMAudioComponentTypeLowPassFilter,
    AMAudioComponentTypeHighPassFilter,
    AMAudioComponentTypeBandPassFilter,
    AMAudioComponentTypeHighShelfFilter,
    AMAudioComponentTypeLowShelfFilter,
    AMAudioComponentTypeParametricEQ,
    AMAudioComponentTypeDistortion,
    AMAudioComponentTypeiPodEQ,
    AMAudioComponentTypeNBandEQ,
    
    /** Mixers */
    AMAudioComponentTypeMultiChannelMixer,
    AMAudioComponentType3DMixerEmbedded,
    
    /** Generators */
    AMAudioComponentTypeScheduledSoundPlayer,
    AMAudioComponentTypeAudioFilePlayer,
    
    /** Music Instruments */
    AMAudioComponentTypeSampler,
    
    /** Input/Output */
    AMAudioComponentTypeGenericOutput,
    AMAudioComponentTypeRemoteIO,
    AMAudioComponentTypeVoiceProcessingIO,
    
    AMAudioComponentTypeCustom
    
} AMAudioComponentType;

@interface AMAudioUnitNode : NSObject {
    AUNode _node;
    AudioUnit _audioUnit;
    AMAudioUnitGraph* _graph;
}

/**
 Accessors for the StreamFormat property
 @see kAudioUnitProperty_StreamFormat
 */
- (void)setStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;
- (void)getStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;

/**
 Accessors for the SampleRate property
 @see kAudioUnitProperty_SampleRate
 */
- (void)setSampleRate:(Float64)sampleRate scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;
- (Float64)getSampleRateInScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus;

/**
 Accessors for the Bus Count (ElementCount) property
 @see kAudioUnitProperty_ElementCount
 */
- (void)setBusCount:(UInt32)busCount scope:(AudioUnitScope)scope;
- (UInt32)getBusCountInScope:(AudioUnitScope)scope;

@end
