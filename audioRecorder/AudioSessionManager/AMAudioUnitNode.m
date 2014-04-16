//
//  AMAudioUnitNode.m
//  audio
//
//  Created by Hai Le on 10/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMAudioUnitNode.h"
#import "AMAudioUnitException.h"
#import "AMAudioUnitGraph.h"
#import "AMConstants.h"

@interface AMAudioUnitGraph (Protected)
- (AUGraph)AUGraph;
@end

@interface AMAudioUnitNode (Protected)
- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType;
- (AUNode)AUNode;
- (AudioUnit)AudioUnit;
@end

@interface AMAudioUnitNode (Private)
+ (void)fillOutComponentDescription:(AudioComponentDescription*)description withType:(AMAudioComponentType)type;
@end

@implementation AMAudioUnitNode

#pragma mark - Initialize

- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType {
    self = [super init];
    if (self && componentType != AMAudioComponentTypeCustom) {
        AudioComponentDescription description;
        [AMAudioUnitNode fillOutComponentDescription:&description withType:componentType];
        AMAudioThrowIfErr(AUGraphAddNode([graph AUGraph], &description, &_node));
        AUGraphNodeInfo([graph AUGraph], _node, NULL, &_audioUnit);
        
        _graph = graph;
    }
    return self;
}
- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph {
    
    self = [super init];
    return self;
}

#pragma mark - Public Interface

- (void)setMaximumFramesPerSlice:(UInt32)maximumFramesPerSlice {
    NSParameterAssert(maximumFramesPerSlice != 0);
    AMAudioThrowIfErr(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof(UInt32)));
}

- (UInt32)maximumFramesPerSlice {
    UInt32 maximumFramesPerSlice = 0;
    UInt32 dataSize = sizeof(UInt32);
    AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, &dataSize));
    return maximumFramesPerSlice;
}

- (void)setStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    AMAudioThrowIfErr(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, asbd, sizeof(AudioStreamBasicDescription)));
}

- (void)getStreamFormat:(AudioStreamBasicDescription*)asbd scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    NSParameterAssert(asbd != NULL);
    UInt32 datasize = sizeof(AudioStreamBasicDescription);
    memset(asbd, 0, datasize);
    AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, asbd, &datasize));
}

- (void)setSampleRate:(Float64)sampleRate scope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    AMAudioThrowIfErr(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SampleRate, scope, bus, &sampleRate, sizeof(Float64)));
}

- (Float64)getSampleRateInScope:(AudioUnitScope)scope bus:(AudioUnitElement)bus {
    Float64 sampleRate = 0;
    UInt32 datasize = sizeof(Float64);
    AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &sampleRate, &datasize));
    return sampleRate;
}

- (void)setBusCount:(UInt32)busCount scope:(AudioUnitScope)scope {
    AMAudioThrowIfErr(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_ElementCount, scope, 0, &busCount, sizeof(UInt32)));
}

- (UInt32)getBusCountInScope:(AudioUnitScope)scope {
    UInt32 busCount;
    UInt32 datasize = sizeof(UInt32);
    AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_ElementCount, scope, 0, &busCount, &datasize));
    return busCount;
}



#pragma mark - Protected Interface

- (AUNode)AUNode {
    return _node;
}

- (AudioUnit)AudioUnit {
    return _audioUnit;
}

#pragma mark - Private Interface

+ (void)fillOutComponentDescription:(AudioComponentDescription*)description withType:(AMAudioComponentType)type {
    if (!description) {
        return;
    }
    
    memset(description, 0, sizeof(AudioComponentDescription));
    description->componentManufacturer = kAudioUnitManufacturer_Apple;
    
    switch (type) {
            
            /** Converters */
        case AMAudioComponentTypeConverter:
            description->componentType      = kAudioUnitType_FormatConverter;
            description->componentSubType   = kAudioUnitSubType_AUConverter;
            break;
            
        case AMAudioComponentTypeVariSpeed :
            description->componentType      = kAudioUnitType_FormatConverter;
            description->componentSubType   = kAudioUnitSubType_Varispeed;
            break;
            
        case AMAudioComponentTypeiPodTime :
            description->componentType      = kAudioUnitType_FormatConverter;
            description->componentSubType   = kAudioUnitSubType_AUiPodTime;
            break;
            
        case AMAudioComponentTypeiPodTimeOther:
            description->componentType      = kAudioUnitType_FormatConverter;
            description->componentSubType   = kAudioUnitSubType_AUiPodTimeOther;
            break;
            
            /** Effects */
        case AMAudioComponentTypePeakLimiter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_PeakLimiter;
            break;
            
        case AMAudioComponentTypeDynamicsProcessor:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_DynamicsProcessor;
            break;
            
        case AMAudioComponentTypeReverb2:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_Reverb2;
            break;
            
        case AMAudioComponentTypeLowPassFilter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_LowPassFilter;
            break;
            
        case AMAudioComponentTypeHighPassFilter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_HighPassFilter;
            break;
            
        case AMAudioComponentTypeBandPassFilter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_BandPassFilter;
            break;
            
        case AMAudioComponentTypeHighShelfFilter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_HighShelfFilter;
            break;
            
        case AMAudioComponentTypeLowShelfFilter:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_LowShelfFilter;
            break;
            
        case AMAudioComponentTypeParametricEQ:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_ParametricEQ;
            break;
            
        case AMAudioComponentTypeDistortion:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_Distortion;
            break;
            
        case AMAudioComponentTypeiPodEQ:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_AUiPodEQ;
            break;
            
        case AMAudioComponentTypeNBandEQ:
            description->componentType      = kAudioUnitType_Effect;
            description->componentSubType   = kAudioUnitSubType_NBandEQ;
            break;
            
            /** Mixers */
        case AMAudioComponentTypeMultiChannelMixer:
            description->componentType      = kAudioUnitType_Mixer;
            description->componentSubType   = kAudioUnitSubType_MultiChannelMixer;
            break;
            
        case AMAudioComponentType3DMixerEmbedded:
            description->componentType      = kAudioUnitType_Mixer;
            description->componentSubType   = kAudioUnitSubType_AU3DMixerEmbedded;
            break;
            
            /** Generators */
        case AMAudioComponentTypeScheduledSoundPlayer:
            description->componentType      = kAudioUnitType_Generator;
            description->componentSubType   = kAudioUnitSubType_ScheduledSoundPlayer;
            break;
            
        case AMAudioComponentTypeAudioFilePlayer:
            description->componentType      = kAudioUnitType_Generator;
            description->componentSubType   = kAudioUnitSubType_AudioFilePlayer;
            break;
            
            /** Music Instruments */
        case AMAudioComponentTypeSampler :
            description->componentType      = kAudioUnitType_MusicDevice;
            description->componentSubType   = kAudioUnitSubType_Sampler;
            break;
            
            /** Input/Output */
        case AMAudioComponentTypeGenericOutput:
            description->componentType      = kAudioUnitType_Output;
            description->componentSubType   = kAudioUnitSubType_GenericOutput;
            break;
            
        case AMAudioComponentTypeRemoteIO:
            description->componentType      = kAudioUnitType_Output;
            description->componentSubType   = kAudioUnitSubType_RemoteIO;
            break;
            
        case AMAudioComponentTypeVoiceProcessingIO:
            description->componentType      = kAudioUnitType_Output;
            description->componentSubType   = kAudioUnitSubType_VoiceProcessingIO;
            break;
        
        case AMAudioComponentTypeCustom:
            NSLog(@"N/A component");
            break;
    }
}


@end
