//
//  AudioSessionManager.m
//  audio
//
//  Created by Hai Le on 8/1/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMAudioSessionIO.h"
#import "Configs.h"

static AMAudioSessionIO *sharedInstance = nil;

@interface AMAudioSessionIO ()
@end

@implementation AMAudioSessionIO

@synthesize inputDeviceAvailable    = _inputDeviceAvailable;
@synthesize graphSampleRate         = _graphSampleRate;
@synthesize inputNumberOfChannels   = _inputNumberOfChannels;
@synthesize bufferDuration          = _bufferDuration;
@synthesize isRecording             = _isRecording;
@synthesize takein,takeout;
@synthesize volume;
@synthesize lpf;
@synthesize hpf;
@synthesize bpf;

#pragma mark - Singleton

+ (AMAudioSessionIO*) sharedInstance
{
	@synchronized(self)
	{
		if (sharedInstance == nil) {
			sharedInstance = [[AMAudioSessionIO alloc] init];
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

#pragma mark - Initialize
- (id) init {
    if ([super init])
	{
        // Initialise buffer
        [self initAudioSession];
        [self initAudioUnits];
        [self initAudioSessionNotification];
    }
	return self;
}

#pragma mark - Public methods

- (void)startRecording {
    [_graph start];
    // Start processing thread
    _isRecording = YES;
}

- (void)stopRecording {
    [_graph stop];
    
    // Stop processing thread
    _isRecording = NO;
}

#pragma mark - Private methods

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

- (void)initAudioStreamDescription {
}

- (void)initAudioUnits {
    AMDigitalFilter *lowpass = [[AMDigitalFilter alloc] initWithFilterType:butterworthLPF];
    
    AMDigitalFilter *highpass = [[AMDigitalFilter alloc] initWithFilterType:butterworthHPF];
    
    AMDigitalFilter *bandpass = [[AMDigitalFilter alloc] initWithFilterType:butterworthBPF];
    
    _graph = [[AMAudioUnitGraph alloc] init];
    
    AMVoiceProcessing *ioNode = [_graph addNodeWithClass:[AMVoiceProcessing class]];
    [ioNode setOutputSilient:YES];
//    AMMultiChannelMixer *mixer = [_graph addNodeWithClass:[AMMultiChannelMixer class]];
//    //[mixer setMaximumFramesPerSlice:4096]; // optional, enables playback during screen lock
//    [mixer setBusCount:2 scope:kAudioUnitScope_Input]; // define 2 inputs busses on the mixer
//    //[mixer connectOutput:0 toInput:0 ofNode:ioNode];
//    
//    AMAudioUnitNode *lowpassNode = [_graph addNodeWithType:AMAudioComponentTypeLowPassFilter];
//    [_graph connectOutput:kInputElement ofNode:ioNode toInput:0 ofNode:lowpassNode];
    
    [_graph start];
    [ioNode setInputCallbackEnabled:YES bus:kOutputElement];
    ioNode.inBlock = ^OSStatus(float* left, SInt16*right, UInt32 inNumberFrames) {
        //volume  = getMeanVolumeSint16(left, inNumberFrames);
        
        lpf = [lowpass calculate:volume];
        hpf = [highpass calculate:volume];
        bpf = [bandpass calculate:volume];
        return noErr;
    };
}

- (void)initAudioSessionNotification {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Register for Route Change notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: audioSession];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: audioSession];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleMediaServicesWereReset:)
                                                 name: AVAudioSessionMediaServicesWereResetNotification
                                               object: audioSession];
}


#pragma mark - Handle Notification (iOS 6++)
-(void)handleMediaServicesWereReset:(NSNotification*)notification{
    //  If the media server resets for any reason, handle this notification to reconfigure audio or do any housekeeping, if necessary
    //    • No userInfo dictionary for this notification
    //      • Audio streaming objects are invalidated (zombies)
    //      • Handle this notification by fully reconfiguring audio
    NSLog(@"handleMediaServicesWereReset: %@ ",[notification name]);
}

-(void)handleInterruption:(NSNotification*)notification{
    NSInteger reason = 0;
    NSString* reasonStr=@"";
    //
    // AVAudioSessionInterruptionNotification
    //      Posted when an audio interruption occurs.
    if ([notification.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
        
        reason = [[[notification userInfo] objectForKey:@" AVAudioSessionInterruptionTypeKey"] integerValue];
        //       Audio has stopped, already inactive
        //       Change state of UI, etc., to reflect non-playing state
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            
            //if(soundSessionIO_.isProcessingSound)[soundSessionIO_ stopSoundProcessing:nil];
        }
        
        //       Make session active
        //       Update user interface
        //       AVAudioSessionInterruptionOptionShouldResume option
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber* seccondReason = [[notification userInfo] objectForKey:@"AVAudioSessionInterruptionOptionKey"] ;
            switch ([seccondReason integerValue]) {
                case AVAudioSessionInterruptionOptionShouldResume:
                    //          Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    break;
                default:
                    break;
            }
        }
        
        //
        // AVAudioSessionDidBeginInterruptionNotification
        //      Posted after an interruption in your audio session occurs.
        //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        if ([notification.name isEqualToString:@"AVAudioSessionDidBeginInterruptionNotification"]) {
            //if (soundSessionIO_.isProcessingSound) {
                
            //}
        }
        
        //
        // AVAudioSessionDidEndInterruptionNotification
        //      Posted after an interruption in your audio session ends.
        //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        if ([notification.name isEqualToString:@"AVAudioSessionDidEndInterruptionNotification"]) {
        }
        
        //
        // AVAudioSessionInputDidBecomeAvailableNotification
        //      Posted when an input to the audio session becomes available.
        //      This notification is posted on the main thread of your app. There is no userInfo dictionary.

        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeAvailableNotification"]) {
        }
        
        //
        // AVAudioSessionInputDidBecomeUnavailableNotification
        //      Posted when an input to the audio session becomes unavailable.
        //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeUnavailableNotification"]) {
        }
        
    };
    NSLog(@"handleInterruption: %@ reason %@",[notification name],reasonStr);
}

- (void)handleRouteChange:(NSNotification*)notification{
    AVAudioSession *session = [ AVAudioSession sharedInstance ];
    NSString* seccReason = @"";
    NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count]?session.currentRoute.inputs:nil objectAtIndex:0];
    if (input.portType == AVAudioSessionPortHeadsetMic) {
        
    }
}

@end
