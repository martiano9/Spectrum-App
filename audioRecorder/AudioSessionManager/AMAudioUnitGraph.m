//
//  AMAudioGraph.m
//  audio
//
//  Created by Hai Le on 9/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMAudioUnitGraph.h"
#import "AMAudioUnitException.h"
#import "AudioManager.h"

@interface AMAudioUnitNode (Protected)
- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType;
- (AUNode)AUNode;
@end

@interface AMAudioUnitGraph (Protected)
- (AUGraph)AUGraph;
@end

@implementation AMAudioUnitGraph

@synthesize inputDeviceAvailable    = _inputDeviceAvailable;
@synthesize graphSampleRate         = _graphSampleRate;
@synthesize inputNumberOfChannels   = _inputNumberOfChannels;
@synthesize bufferDuration          = _bufferDuration;

#pragma mark - Initialize

- (id)init {
    self = [super init];
    if (self) {
        AMAudioThrowIfErr(NewAUGraph(&_auGraph));
        AMAudioThrowIfErr(AUGraphOpen(_auGraph));
        AMAudioThrowIfErr(AUGraphInitialize(_auGraph));
        _nodes = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
    [_nodes removeAllObjects];
    AMAudioThrowIfErr(AUGraphUninitialize(_auGraph));
    AMAudioThrowIfErr(AUGraphClose(_auGraph));
    AMAudioThrowIfErr(DisposeAUGraph(_auGraph));
}

#pragma mark - Private Interface

- (void)initAudioSession
{
    // Get singleton instance of Audio Session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    
	// Check if input is available (this only really applies to older ipod touch without builtin mic)
    _inputDeviceAvailable = [audioSession isInputAvailable];
    
    // If input's available set category to PlayAndRecord
    if (_inputDeviceAvailable) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
        checkError(err, "setting audio session category Play and Record");
        
        [audioSession setMode:AVAudioSessionModeMeasurement error:&err];
        checkError(err, "setting audio session mode measurement");
    }
    // else set to Playback only
    else {
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&err];
        checkError(err, "setting audio session category Playback");
    }
    
    // Request the desired hardware sample rate.
    [audioSession setPreferredSampleRate:kSampleRate error:&err];
    checkError(err, "setting preferred hardware sample rate");
	
	// Request preferred buffer duration
	[audioSession setPreferredIOBufferDuration:kBufferDuration error:&err];
    checkError(err, "setting preferred buffer duraton");
    
    // Active audio session
    [audioSession setActive:YES error: &err];
    checkError(err, "active audio session");
    
    // Get info
    _graphSampleRate        = [audioSession sampleRate];
    _inputNumberOfChannels  = [audioSession inputNumberOfChannels];
    _bufferDuration         = [audioSession IOBufferDuration];
    
    return;
}

#pragma mark - Public Interface

- (void)start {
    if ([self isRunning]) {
        return;
    }
    [self willChangeValueForKey:@"running"];
    AMAudioThrowIfErr(AUGraphStart(_auGraph));
    [self didChangeValueForKey:@"running"];
}

- (void)stop {
    if ([self isRunning] == NO) {
        return;
    }
    [self willChangeValueForKey:@"running"];
    AMAudioThrowIfErr(AUGraphStop(_auGraph));
    [self didChangeValueForKey:@"running"];
}

- (BOOL)isRunning {
    Boolean result;
    AMAudioThrowIfErr(AUGraphIsRunning(_auGraph, &result));
    return result;
}

- (void)setRunning:(BOOL)running {
    if (running) {
        [self start];
    } else {
        [self stop];
    }
}

- (id)addNodeWithType:(AMAudioComponentType)type {
    id node = [[AMAudioUnitNode alloc] initWithAudioGraph:self audioComponent:type];
    [_nodes addObject:node];
    return node;
}

- (id)addNodeWithClass:(Class)nodeClass {
    id node;
    if (nodeClass == [AMVoiceProcessing class]) {
        node = [[AMVoiceProcessing alloc] initWithAudioGraph:self audioComponent:AMAudioComponentTypeCustom];
    } else if (nodeClass == [AMMultiChannelMixer class]) {
        node = [[AMMultiChannelMixer alloc] initWithAudioGraph:self audioComponent:AMAudioComponentTypeCustom];
    }
    [_nodes addObject:node];
    return node;
}


- (void)removeNode:(AMAudioUnitNode*)node {
    AMAudioThrowIfErr(AUGraphRemoveNode(_auGraph, [node AUNode]));
    [_nodes removeObject:node];
}

- (void)updateSynchronous {
    AMAudioThrowIfErr(AUGraphUpdate(_auGraph, NULL));
}

- (void)connectInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode toOutput:(AudioUnitElement)outBus ofNode:(AMAudioUnitNode*)outNode {
    AMAudioThrowIfErr(AUGraphConnectNodeInput(_auGraph, [outNode AUNode], outBus, [inNode AUNode], inBus));
}

- (void)connectOutput:(AudioUnitElement)outBus ofNode:(AMAudioUnitNode*)outNode toInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode {
    AMAudioThrowIfErr(AUGraphConnectNodeInput(_auGraph, [outNode AUNode], outBus, [inNode AUNode], inBus));
}

- (void)disconnectInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode {
    AMAudioThrowIfErr(AUGraphDisconnectNodeInput(_auGraph, [inNode AUNode], inBus));
}

- (void)disconnectAll {
    AMAudioThrowIfErr(AUGraphClearConnections(_auGraph));
}


#pragma mark - Protected Interface

- (AUGraph)AUGraph {
    return _auGraph;
}

@end
