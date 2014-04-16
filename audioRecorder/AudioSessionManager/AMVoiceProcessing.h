//
//  VoiceProcessing.h
//  audio
//
//  Created by Hai Le on 11/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMAudioUnitNode.h"

@interface AMVoiceProcessing : AMAudioUnitNode 

@property BOOL outputSilient;
@property (nonatomic,copy) OSStatus(^inBlock)(float *data, UInt32 numFrames, UInt32 numChannels);
@property (nonatomic) AMDCRejectionFilter* leftChanelFilter;
@property (nonatomic) AMDCRejectionFilter* rightChanelFilter;
@property (nonatomic, assign) AudioBufferList *processABL;
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic, assign, readwrite) float *inData;

- (void)setInputEnable:(BOOL)enable;
- (BOOL)getInputEnable;

- (void)setStreamFormatInputElement:(AudioStreamBasicDescription*)asbd;
- (void)setStreamFormatOutputElement:(AudioStreamBasicDescription*)asbd;

- (void)setInputCallbackEnabled:(BOOL)enable bus:(AudioUnitElement)bus;

@end
