// Copyright (c) 2012 Alex Wiltschko
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// TODO:
// Switching mic and speaker on/off
//
// HOUSEKEEPING AND NICE FEATURES:
// Disambiguate outputFormat (the AUHAL's stream format)
// More nuanced input detection on the Mac
// Route switching should work, check with iPhone
// Device switching should work, check with laptop. Read that damn book.
// Wrap logging with debug macros.
// Think about what should be public, what private.
// Ability to select non-default devices.


#import "Novocaine.h"
#define kInputBus 1
#define kOutputBus 0
#define kDefaultDevice 999999

#import "TargetConditionals.h"

static Novocaine *audioManager = nil;

@interface Novocaine()

// redeclare readwrite for class continuation
@property (nonatomic, assign, readwrite) AudioUnit inputUnit;
@property (nonatomic, assign, readwrite) AudioUnit outputUnit;
@property (nonatomic, assign, readwrite) AudioBufferList *inputBuffer;
@property (nonatomic, assign, readwrite) BOOL inputAvailable;
@property (nonatomic, assign, readwrite) UInt32 numInputChannels;
@property (nonatomic, assign, readwrite) UInt32 numOutputChannels;
@property (nonatomic, assign, readwrite) Float64 samplingRate;
@property (nonatomic, assign, readwrite) BOOL isInterleaved;
@property (nonatomic, assign, readwrite) UInt32 numBytesPerSample;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription inputFormat;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign, readwrite) BOOL playing;
@property (nonatomic, assign, readwrite) float *inData;
@property (nonatomic, assign, readwrite) float *outData;

#if defined (USING_OSX)
@property (nonatomic, assign) AudioDeviceID *deviceIDs;
@property (nonatomic, strong) NSMutableArray *deviceNames;
@property (nonatomic, assign) AudioDeviceID defaultInputDeviceID;
@property (nonatomic, strong) NSString *defaultInputDeviceName;
@property (nonatomic, assign) AudioDeviceID defaultOutputDeviceID;
@property (nonatomic, strong) NSString *defaultOutputDeviceName;
- (void)enumerateAudioDevices;
#endif

// must be called prior to playing audio
- (void)setupAudioSession;
- (void)setupAudioUnits;

- (NSString *)applicationDocumentsDirectory;

- (void)freeBuffers;

@end


@implementation Novocaine

#pragma mark - Singleton Methods
+ (Novocaine *) audioManager
{
	@synchronized(self)
	{
		if (audioManager == nil) {
			audioManager = [[Novocaine alloc] init];
		}
	}
    return audioManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (audioManager == nil) {
            audioManager = [super allocWithZone:zone];
            return audioManager;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

// ND: If NSCopying protocol is to be supported, it should be declared with class and done correctly. Disabled for now.

//- (id)copyWithZone:(NSZone *)zone
//{
//    return self;
//}

static void printASBD(AudioStreamBasicDescription asbd) {
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10ld",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10ld",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10ld",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10ld",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10ld",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10ld",    asbd.mBitsPerChannel);
}

- (id)init
{
	if (self = [super init])
	{
        
        // Initialize a float buffer to hold audio
		self.inData  = (float *)calloc(8192, sizeof(float)); // probably more than we'll need
        self.outData = (float *)calloc(8192, sizeof(float));
        
        self.inputBlock = nil;
        self.outputBlock = nil;
        
        self.playing = NO;
        // self.playThroughEnabled = NO;
		
		// Fire up the audio session ( with steady error checking ... )
        [self setupAudioSession];
        
        // start audio units
        [self setupAudioUnits];
		
		return self;
		
	}
	
	return nil;
}

- (void)dealloc
{
    free(self.inData);
    free(self.outData);
    
#if defined (USING_OSX)
    if (self.deviceIDs){
        free(self.deviceIDs);
    }
#endif
    
    [self freeBuffers];
}

- (void)freeBuffers
{
    if (self.inputBuffer){
        
		for(UInt32 i =0; i< self.inputBuffer->mNumberBuffers ; i++) {

			if(self.inputBuffer->mBuffers[i].mData){
                free(self.inputBuffer->mBuffers[i].mData);
            }
		}
        
        free(self.inputBuffer);
        self.inputBuffer = NULL;
    }
}

#pragma mark - Properties

// TODO: Implement this.
//- (void)setInputEnabled:(BOOL)inputEnabled
//{
//    _inputEnabled = inputEnabled;
//}

#ifdef USING_IOS
- (void)setForceOutputToSpeaker:(BOOL)forceOutputToSpeaker
{
    
#if !TARGET_IPHONE_SIMULATOR
//    UInt32 value = forceOutputToSpeaker ? 1 : 0;
//    // should not be fatal error
//    OSStatus err = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(UInt32), &value);
//    if (err != noErr){
//        NSLog(@"Could not override audio output route to speaker");
//    }
//    else{
//        _forceOutputToSpeaker = forceOutputToSpeaker;
//    }
#else
    _forceOutputToSpeaker = forceOutputToSpeaker;
#endif
}
#endif

#pragma mark - Audio Methods


- (void)setupAudioSession
{
    // Initialize and configure the audio session, and add an interuption listener
    // Set the audio session active
    NSError *err = nil;
    if (![[AVAudioSession sharedInstance] setActive:YES error:&err]){
        NSLog(@"Couldn't activate audio session: %@", err);
    }
    [self checkAudioSource];
}


- (void)setupAudioUnits
{
    
    // --- Audio Session Setup ---
    // ---------------------------
    
#if defined ( USING_IOS )
    
    // TODO: Move this somewhere more dynamic - should update category as appropriate to current application behavior
    // Get singleton instance of Audio Session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    checkNSError(err, "Couldn't set audio category");
    
   
    // Add a property listener, to listen to changes to the session
//    CheckError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, sessionPropertyListener, (__bridge void*)self), "Couldn't add audio session property listener");
    
    // Set the buffer size, this will affect the number of samples that get rendered every time the audio callback is fired
    // A small number will get you lower latency audio, but will make your processor work harder
#if !TARGET_IPHONE_SIMULATOR
    Float32 preferredBufferSize = 0.0232;
    [audioSession setPreferredIOBufferDuration:preferredBufferSize error:&err];
    checkNSError(err, "Couldn't set the preferred buffer duration");
#endif

    
    [self checkSessionProperties];
    
#endif
    
    // ----- Audio Unit Setup -----
    // ----------------------------
    
    
    // Describe the output unit.
    
    AudioComponentDescription inputDescription = {0};	
    inputDescription.componentType = kAudioUnitType_Output;
    inputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    inputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &inputDescription);
    CheckError( AudioComponentInstanceNew(inputComponent, &_inputUnit), "Couldn't create the output audio unit");
    
    // Enable input
    // TODO: Conditionally disable input if option has not been specified
    UInt32 one = 1;
    CheckError( AudioUnitSetProperty(_inputUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     kInputBus,
                                     &one,
                                     sizeof(one)), "Couldn't enable IO on the input scope of output unit");
    
    // TODO: first query the hardware for desired stream descriptions
    // Check the input stream format
    
    UInt32 size;
	size = sizeof( AudioStreamBasicDescription );
	CheckError( AudioUnitGetProperty(_inputUnit,
                                     kAudioUnitProperty_StreamFormat, 
                                     kAudioUnitScope_Input, 
                                     1, 
                                     &_inputFormat,
                                     &size ),
               "Couldn't get the hardware input stream format");
	
	// Check the output stream format
	size = sizeof( AudioStreamBasicDescription );
	CheckError( AudioUnitGetProperty(_inputUnit,
                                     kAudioUnitProperty_StreamFormat, 
                                     kAudioUnitScope_Output, 
                                     1, 
                                     &_outputFormat,
                                     &size ), 
               "Couldn't get the hardware output stream format");
    
    // TODO: check this works on iOS!
    _inputFormat.mSampleRate = 44100.0;
    _outputFormat.mSampleRate = 44100.0;
    self.samplingRate = _inputFormat.mSampleRate;
    self.numBytesPerSample = _inputFormat.mBitsPerChannel / 8;
    
    size = sizeof(AudioStreamBasicDescription);
	CheckError(AudioUnitSetProperty(_inputUnit,
									kAudioUnitProperty_StreamFormat,
									kAudioUnitScope_Output,
									kInputBus,
									&_outputFormat,
									size),
			   "Couldn't set the ASBD on the audio unit (after setting its sampling rate)");
    
    UInt32 numFramesPerBuffer;
    size = sizeof(UInt32);
    CheckError(AudioUnitGetProperty(_inputUnit,
                                    kAudioUnitProperty_MaximumFramesPerSlice,
                                    kAudioUnitScope_Global, 
                                    kOutputBus, 
                                    &numFramesPerBuffer, 
                                    &size), 
               "Couldn't get the number of frames per callback");
    
    UInt32 bufferSizeBytes = _outputFormat.mBytesPerFrame * _outputFormat.mFramesPerPacket * numFramesPerBuffer;
    
	if (_outputFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
        // The audio is non-interleaved
        printf("Not interleaved!\n");
        self.isInterleaved = NO;
        
        // allocate an AudioBufferList plus enough space for array of AudioBuffers
		UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * _outputFormat.mChannelsPerFrame);
		
		//malloc buffer lists
		self.inputBuffer = (AudioBufferList *)malloc(propsize);
		self.inputBuffer->mNumberBuffers = _outputFormat.mChannelsPerFrame;
		
		//pre-malloc buffers for AudioBufferLists
		for(UInt32 i =0; i< self.inputBuffer->mNumberBuffers ; i++) {
			self.inputBuffer->mBuffers[i].mNumberChannels = 1;
			self.inputBuffer->mBuffers[i].mDataByteSize = bufferSizeBytes;
			self.inputBuffer->mBuffers[i].mData = malloc(bufferSizeBytes);
            memset(self.inputBuffer->mBuffers[i].mData, 0, bufferSizeBytes);
		}
        
	} else {
		printf ("Format is interleaved\n");
        self.isInterleaved = YES;
        
		// allocate an AudioBufferList plus enough space for array of AudioBuffers
		UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * 1);
		
		//malloc buffer lists
		self.inputBuffer = (AudioBufferList *)malloc(propsize);
		self.inputBuffer->mNumberBuffers = 1;
		
		//pre-malloc buffers for AudioBufferLists
		self.inputBuffer->mBuffers[0].mNumberChannels = _outputFormat.mChannelsPerFrame;
		self.inputBuffer->mBuffers[0].mDataByteSize = bufferSizeBytes;
		self.inputBuffer->mBuffers[0].mData = malloc(bufferSizeBytes);
        memset(self.inputBuffer->mBuffers[0].mData, 0, bufferSizeBytes);
        
	}
    
    
    // Slap a render callback on the unit
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    CheckError( AudioUnitSetProperty(_inputUnit,
                                     kAudioOutputUnitProperty_SetInputCallback, 
                                     kAudioUnitScope_Global,
                                     0, 
                                     &callbackStruct, 
                                     sizeof(callbackStruct)), "Couldn't set the callback on the input unit");
    
    
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);

    CheckError( AudioUnitSetProperty(_inputUnit,
                                     kAudioUnitProperty_SetRenderCallback, 
                                     kAudioUnitScope_Input,
                                     0,
                                     &callbackStruct, 
                                     sizeof(callbackStruct)), 
               "Couldn't set the render callback on the input unit");
	CheckError(AudioUnitInitialize(_inputUnit), "Couldn't initialize the output unit");
}

- (void)pause {
	
	if (self.playing) {
        CheckError( AudioOutputUnitStop(_inputUnit), "Couldn't stop the output unit");
		self.playing = NO;
	}
    
}

- (void)play {
	printASBD(self.inputFormat);
    printASBD(self.outputFormat);
	UInt32 isInputAvailable=0;
    
    isInputAvailable = [[AVAudioSession sharedInstance] isInputAvailable];
    
    self.inputAvailable = isInputAvailable;
    
	if ( self.inputAvailable ) {
		// Set the audio session category for simultaneous play and record
		if (!self.playing) {
			CheckError( AudioOutputUnitStart(_inputUnit), "Couldn't start the output unit");
            self.playing = YES;
            
		}
	}
    
}


#pragma mark - Render Methods
OSStatus inputCallback   (void						*inRefCon,
                          AudioUnitRenderActionFlags	* ioActionFlags,
                          const AudioTimeStamp 		* inTimeStamp,
                          UInt32						inOutputBusNumber,
                          UInt32						inNumberFrames,
                          AudioBufferList			* ioData)
{
    @autoreleasepool {
    
        Novocaine *sm = (__bridge Novocaine *)inRefCon;
        
        if (!sm.playing)
            return noErr;
        if (sm.inputBlock == nil)
            return noErr;    
        
        
        // Check the current number of channels		
        // Let's actually grab the audio
#if TARGET_IPHONE_SIMULATOR
        // this is a workaround for an issue with core audio on the simulator, //
        //  likely due to 44100 vs 48000 difference in OSX //
        if( inNumberFrames == 471 )
            inNumberFrames = 470;
#endif
        CheckError( AudioUnitRender(sm.inputUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, sm.inputBuffer), "Couldn't render the output unit");
        
        
        // Convert the audio in something manageable
        // For Float32s ... 
        if ( sm.numBytesPerSample == 4 ) // then we've already got flaots
        {
            
            float zero = 0.0f;
            if ( ! sm.isInterleaved ) { // if the data is in separate buffers, make it interleaved
                for (int i=0; i < sm.numInputChannels; ++i) {
                    vDSP_vsadd((float *)sm.inputBuffer->mBuffers[i].mData, 1, &zero, sm.inData+i, 
                               sm.numInputChannels, inNumberFrames);
                }
            } 
            else { // if the data is already interleaved, copy it all in one happy block.
                // TODO: check mDataByteSize is proper 
                memcpy(sm.inData, (float *)sm.inputBuffer->mBuffers[0].mData, sm.inputBuffer->mBuffers[0].mDataByteSize);
            }
        }
        
        // For SInt16s ...
        else if ( sm.numBytesPerSample == 2 ) // then we're dealing with SInt16's
        {
            if ( ! sm.isInterleaved ) {
                for (int i=0; i < sm.numInputChannels; ++i) {
                    vDSP_vflt16((SInt16 *)sm.inputBuffer->mBuffers[i].mData, 1, sm.inData+i, sm.numInputChannels, inNumberFrames);
                }            
            }
            else {
                vDSP_vflt16((SInt16 *)sm.inputBuffer->mBuffers[0].mData, 1, sm.inData, 1, inNumberFrames*sm.numInputChannels);
            }
            
            float scale = 1.0 / (float)INT16_MAX;
            vDSP_vsmul(sm.inData, 1, &scale, sm.inData, 1, inNumberFrames*sm.numInputChannels);
        }
        
        // Now do the processing! 
        sm.inputBlock(sm.inData, inNumberFrames, sm.numInputChannels);
        
    }
    
    return noErr;
	
	
}

OSStatus renderCallback (void						*inRefCon,
                         AudioUnitRenderActionFlags	* ioActionFlags,
                         const AudioTimeStamp 		* inTimeStamp,
                         UInt32						inOutputBusNumber,
                         UInt32						inNumberFrames,
                         AudioBufferList				* ioData)
{
    // autorelease pool for much faster ARC performance on repeated calls from separate thread
    @autoreleasepool {
        
        Novocaine *sm = (__bridge Novocaine *)inRefCon;
        float zero = 0.0;
        
        
        for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
            memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
        }
        
        if (!sm.playing)
            return noErr;
        if (!sm.outputBlock)
            return noErr;
        
        
        // Collect data to render from the callbacks
        sm.outputBlock(sm.outData, inNumberFrames, sm.numOutputChannels);
        
        
        // Put the rendered data into the output buffer
        // TODO: convert SInt16 ranges to float ranges.
        if ( sm.numBytesPerSample == 4 ) // then we've already got floats
        {
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {

                    int interleaveOffset = iChannel;
                    if (iBuffer < sm.numOutputChannels){
                        interleaveOffset += iBuffer;
                    }
                    
                    vDSP_vsadd(sm.outData+interleaveOffset, sm.numOutputChannels, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, inNumberFrames);
                    
                }
            }
        }
        else if ( sm.numBytesPerSample == 2 ) // then we need to convert SInt16 -> Float (and also scale)
        {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(sm.outData, 1, &scale, sm.outData, 1, inNumberFrames*sm.numOutputChannels);
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    
                    int interleaveOffset = iChannel;
                    if (iBuffer < sm.numOutputChannels){
                        interleaveOffset += iBuffer;
                    }
                    
                    vDSP_vfix16(sm.outData+interleaveOffset, sm.numOutputChannels, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, inNumberFrames);
                }
            }
            
        }
    }

    return noErr;
    
}	

#pragma mark - Audio Session Listeners
#if defined (USING_IOS)
void sessionPropertyListener(void *                  inClientData,
							 AudioSessionPropertyID  inID,
							 UInt32                  inDataSize,
							 const void *            inData){
	
    // Determines the reason for the route change, to ensure that it is not
    //      because of a category change.
    CFNumberRef routeChangeReasonRef = (CFNumberRef)CFDictionaryGetValue ((CFDictionaryRef)inData, CFSTR (kAudioSession_AudioRouteChangeKey_Reason) );
    SInt32 routeChangeReason;
    CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
    
    if (inID == kAudioSessionProperty_AudioRouteChange && routeChangeReason != kAudioSessionRouteChangeReason_CategoryChange)
    {
        Novocaine *sm = (__bridge Novocaine *)inClientData;
        [sm checkSessionProperties];
    }
    
}

- (void)checkAudioSource {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Check what the incoming audio route is.
//    UInt32 propertySize = sizeof(CFStringRef);
//    CFStringRef route;
//    CheckError( AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route), "Couldn't check the audio route");
//    self.inputRoute = (__bridge NSString *)route;
//    CFRelease(route);
//    NSLog(@"AudioRoute: %@", self.inputRoute);
    
    
    // Check if there's input available.
    // TODO: check if checking for available input is redundant.
    //          Possibly there's a different property ID change?
    self.inputAvailable = [audioSession isInputAvailable];
    NSLog(@"Input available? %d", self.inputAvailable);
    
}


// To be run ONCE per session property change and once on initialization.
- (void)checkSessionProperties
{	
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Check if there is input, and from where
    [self checkAudioSource];
    
    // Check the number of input channels.
    // Find the number of channels
    self.numInputChannels = [audioSession inputNumberOfChannels];
    NSLog(@"We've got %lu input channels", self.numInputChannels);
    
    // Get the hardware sampling rate. This is settable, but here we're only reading.
    self.samplingRate = [audioSession sampleRate];
    NSLog(@"Current sampling rate: %f", self.samplingRate);
	
}

void sessionInterruptionListener(void *inClientData, UInt32 inInterruption) {
    
	Novocaine *sm = (__bridge Novocaine *)inClientData;
    
	if (inInterruption == kAudioSessionBeginInterruption) {
		NSLog(@"Begin interuption");
		sm.inputAvailable = NO;
	}
	else if (inInterruption == kAudioSessionEndInterruption) {
		NSLog(@"End interuption");	
		sm.inputAvailable = YES;
		[sm play];
	}
	
}

#endif

#pragma mark - Convenience Methods
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end








