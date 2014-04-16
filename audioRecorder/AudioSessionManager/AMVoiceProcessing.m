//
//  VoiceProcessing.m
//  audio
//
//  Created by Hai Le on 11/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMVoiceProcessing.h"
#import "AMAudioUnitException.h"
#import "AMConstants.h"
#import "AMAudioUnitGraph.h"
#import "AMDCRejectionFilter.h"
#import "AMErrorHelper.h"

@interface AMAudioUnitGraph (Protected)
- (AUGraph)AUGraph;
@end

@interface AMAudioUnitNode (Protected)
- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType;
- (AUNode)AUNode;
- (AudioUnit)AudioUnit;
@end

@implementation AMVoiceProcessing {
    AudioStreamBasicDescription _inputStream;
    AudioStreamBasicDescription _outputStream;
}

@synthesize leftChanelFilter = _leftChanelFilter;
@synthesize rightChanelFilter = _rightChanelFilter;
@synthesize processABL = _processABL;
@synthesize audioConverter = _audioConverter;
@synthesize outputSilient = _outputSilient;

- (id)initWithAudioGraph:(AMAudioUnitGraph*)graph audioComponent:(AMAudioComponentType)componentType {
    self = [super initWithAudioGraph:graph audioComponent:AMAudioComponentTypeRemoteIO];
    if (self) {
        // Set default value of outputSilient
        _outputSilient = YES;
        
        // Enable Input from microphone by default
        [self setInputEnable:YES];
        
        // Defaul stream format for input and output
        int channels = [[AVAudioSession sharedInstance] inputNumberOfChannels]==1 ? 1 : 2;
        int bytesPerSample = sizeof (AudioUnitSampleType);
        
        _inputStream.mFormatID           = kAudioFormatLinearPCM;
        _inputStream.mFormatFlags        = kAudioFormatFlagsAudioUnitCanonical;
        _inputStream.mBytesPerPacket     = bytesPerSample;
        _inputStream.mFramesPerPacket    = 1;
        _inputStream.mBytesPerFrame      = bytesPerSample;
        _inputStream.mChannelsPerFrame   = channels;                    // 2 indicates stereo
        _inputStream.mBitsPerChannel     = 8 * bytesPerSample;
        _inputStream.mSampleRate         = kSampleRate;
        
        _outputStream.mFormatID           = kAudioFormatLinearPCM;
        _outputStream.mFormatFlags        = kAudioFormatFlagsAudioUnitCanonical;
        _outputStream.mBytesPerPacket     = bytesPerSample;
        _outputStream.mFramesPerPacket    = 1;
        _outputStream.mBytesPerFrame      = bytesPerSample;
        _outputStream.mChannelsPerFrame   = channels;                    // 2 indicates stereo
        _outputStream.mBitsPerChannel     = 8 * bytesPerSample;
        _outputStream.mSampleRate         = kSampleRate;
        
        [self setStreamFormatInputElement:&_inputStream];
        [self setStreamFormatOutputElement:&_inputStream];
        
        self.inData  = (float *)calloc(8192, sizeof(float));
    }
    return self;
}

#pragma mark - Public Interface

- (void)setInputEnable:(BOOL)enable {
    UInt32 uEnable = enable;
    AMAudioThrowIfErr(AudioUnitSetProperty(_audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           kInputElement,
                                           &uEnable,
                                           sizeof(uEnable)));
}

- (BOOL)getInputEnable {
    UInt32 enabled;
    UInt32 datasize = sizeof(enabled);
    AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           kInputElement,
                                           &enabled,
                                           &datasize));
    return enabled;
}

- (void)setStreamFormatInputElement:(AudioStreamBasicDescription *)asbd {
    [super setStreamFormat:asbd scope:kAudioUnitScope_Output bus:kInputElement];
    _inputStream = *asbd;
}

- (void)setStreamFormatOutputElement:(AudioStreamBasicDescription *)asbd {
    [super setStreamFormat:asbd scope:kAudioUnitScope_Input bus:kOutputElement];
    _outputStream = *asbd;
}

- (void)setInputCallbackEnabled:(BOOL)enable bus:(AudioUnitElement)bus {
    UInt32 maxFPS;
    UInt32 size = sizeof(maxFPS);
    
    if (enable) {
        AMAudioThrowIfErr(AudioUnitGetProperty(_audioUnit,
                                               kAudioUnitProperty_MaximumFramesPerSlice,
                                               kAudioUnitScope_Global,
                                               0,
                                               &maxFPS,
                                               &size));
        
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc        = &renderCallBackProc;
        callbackStruct.inputProcRefCon  = (__bridge void*)self;
        
        AMAudioThrowIfErr(AUGraphSetNodeInputCallback([_graph AUGraph], _node, bus, &callbackStruct));
        
        Boolean graphUpdated;
        AMAudioThrowIfErr(AUGraphUpdate([_graph AUGraph], &graphUpdated));
    }
}

#pragma mark - Callbacks

static OSStatus renderCallBackProc(	void *							inRefCon,
                                   AudioUnitRenderActionFlags *	ioActionFlags,
                                   const AudioTimeStamp *			inTimeStamp,
                                   UInt32							inBusNumber,
                                   UInt32							inNumberFrames,
                                   AudioBufferList *				ioData){
    AMVoiceProcessing *SELF = (__bridge AMVoiceProcessing *)inRefCon;
    AMAudioThrowIfErr(AudioUnitRender( SELF.AudioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData));
    
    AudioUnitSampleType *inSamplesLeft = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    
    if (SELF.inBlock) {
        fixedPointToFloat(inSamplesLeft, SELF.inData, inNumberFrames);
        SELF.inBlock(SELF.inData, inNumberFrames, 2);
    }
    
    if (SELF.outputSilient == YES) {
        SilenceData(ioData);
    }
    
    
    
       return noErr;
}

@end
