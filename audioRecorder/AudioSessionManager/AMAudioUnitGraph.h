//
//  AMAudioGraph.h
//  audio
//
//  Created by Hai Le on 9/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AMAudioUnitNode.h"
#import "AMVoiceProcessing.h"

@interface AMAudioUnitGraph : NSObject {
    AUGraph _auGraph;
    __strong NSMutableSet *_nodes;
}


/**
 Read-only set with AMAudioNode instances that have been added to the receiver.
 */
@property (nonatomic, readonly, strong) NSSet *nodes;

/**
 Read-write BOOL that indicates whether the graph is currently running. Supports KVO.
 */
@property (nonatomic, readwrite, assign, setter = setRunning:, getter = isRunning) BOOL running;

@property (readonly)            bool                        inputDeviceAvailable;
@property (readonly)            NSInteger                   inputNumberOfChannels;
@property (readonly)            Float64                     bufferDuration;
@property (readwrite)           Float64                     graphSampleRate;


/**
 Methods to start or stop the audio processing
 @see -isRunning and -setRunning:
 */
- (void)start;
- (void)stop;

- (id)addNodeWithType:(AMAudioComponentType)type;
- (id)addNodeWithClass:(Class)nodeClass;

- (void)updateSynchronous;
- (void)connectInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode toOutput:(AudioUnitElement)outBus ofNode:(AMAudioUnitNode*)outNode;
- (void)connectOutput:(AudioUnitElement)outBus ofNode:(AMAudioUnitNode*)outNode toInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode;
- (void)disconnectInput:(AudioUnitElement)inBus ofNode:(AMAudioUnitNode*)inNode;
- (void)disconnectAll;

@end
