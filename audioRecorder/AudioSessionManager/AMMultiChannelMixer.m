//
//  YBMultiChannelMixer.m
//  YBAudioUnit
//
//  Created by Martijn Thé on 3/22/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "AMMultiChannelMixer.h"
#import "AudioManager.h"

@interface AMAudioUnitGraph (Protected)
- (AUGraph)AUGraph;
@end

@interface AMAudioUnitNode (Protected)
- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType;
- (AUNode)AUNode;
- (AudioUnit)AudioUnit;
@end

@implementation AMMultiChannelMixer

- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType {
    self = [super initWithAudioGraph:graph audioComponent:AMAudioComponentTypeMultiChannelMixer];
    if (self) {
    
    }
    return self;
}

- (void)setInputEnabled:(BOOL)enabled forBus:(AudioUnitElement)bus {
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)enabled;
    AMAudioThrowIfErr(AudioUnitSetParameter(_audioUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, bus, isOn, 0));
}

- (BOOL)isInputEnabledForBus:(AudioUnitElement)bus {
    AudioUnitParameterValue isOn;
    AMAudioThrowIfErr(AudioUnitGetParameter(_audioUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, bus, &isOn));
    return (isOn == 1.) ? YES : NO;
}

- (void)setVolume:(AudioUnitParameterValue)level forBus:(AudioUnitElement)bus {
    AMAudioThrowIfErr(AudioUnitSetParameter(_audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, bus, level, 0));
}

- (AudioUnitParameterValue)volumeForBus:(AudioUnitElement)bus {
    AudioUnitParameterValue volume;
    AMAudioThrowIfErr(AudioUnitGetParameter(_audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, bus, &volume));
    return volume;
}

- (void)setBalance:(AudioUnitParameterValue)pan forBus:(AudioUnitElement)bus {
    AMAudioThrowIfErr(AudioUnitSetParameter(_audioUnit, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, bus, pan, 0));
}

- (AudioUnitParameterValue)balanceForBus:(AudioUnitElement)bus {
    AudioUnitParameterValue pan;
    AMAudioThrowIfErr(AudioUnitGetParameter(_audioUnit, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, bus, &pan));
    return pan;
}

@end
