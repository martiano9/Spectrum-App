//
//  helper.h
//  audio
//
//  Created by Hai Le on 23/1/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    static inline void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length );
    static inline void fixedPointToFloat ( SInt32 * source, float * target, int length );
    static inline float getMeanVolumeSint16( SInt16 * vector , int length );
    static inline void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length );
    static inline void checkStatus(OSStatus error, const char *operation);
    static inline void checkError(NSError*err, const char *operation);
    static inline void SilenceData(AudioBufferList *inData);
    static inline float getMeanVolumeFloat32( Float32 * vector , int length);
    static inline void printASBD(AudioStreamBasicDescription asbd);
    
#ifdef __cplusplus
}
#endif


////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to SInt16
static inline void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt16) (source[i] >> 9);
        
    }
    
}

////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to Float
static inline void fixedPointToFloat ( SInt32 * source, float * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt16) (source[i] >> 9) / 32768.0;
    }
    
}

////////////////////////////////////////////////////////
// get mean volumn
static inline float getMeanVolumeSint16( SInt16 * vector , int length ) {
    
    
//    // get average input volume level for meter display
//    // by calculating log of mean volume of the buffer
//    // and displaying it to the screen
//    // (note: there's a vdsp function to do this but it works on float samples
//    
//    int sum;
//    int i;
//    float averageVolume;
//    float logVolume;
//    
//    
//    sum = 0;
//    for ( i = 0; i < length ; i++ ) {
//        sum += abs((int) vector[i]);
//    }
//    
//    averageVolume = sum / length;
//    logVolume = averageVolume/32768.0;
//    
//    //    printf("\naverageVolume before scale = %lu", averageVolume );
//    
//    // now convert to logarithm and scale log10(0->32768) into 0->1 for display
//    
//    
////    logVolume = log10f( (float) averageVolume );
////    logVolume = logVolume / log10(32768);
//    logVolume = 20.0*log10f(averageVolume) + -74.0;
//    if (logVolume < 0) logVolume = 0;
//    return (logVolume);
//    
    // These values should be in a more conventional location for a bunch of preprocessor defines in your real code
#define DBOFFSET -60
    // DBOFFSET is An offset that will be used to normalize the decibels to a maximum of zero.
    // This is an estimate, you can do your own or construct an experiment to find the right value
#define LOWPASSFILTERTIMESLICE .001
    // LOWPASSFILTERTIMESLICE is part of the low pass filter and should be a small positive value
    
    SInt16* samples = vector; // Step 1: get an array of your samples that you can loop through. Each sample contains the amplitude.
    
    Float32 decibels = DBOFFSET; // When we have no signal we'll leave this on the lowest setting
    Float32 currentFilteredValueOfSampleAmplitude, previousFilteredValueOfSampleAmplitude; // We'll need these in the low-pass filter
    Float32 peakValue = DBOFFSET; // We'll end up storing the peak value here
    
    for (int i=0; i < length; i++) {
        
        Float32 absoluteValueOfSampleAmplitude = abs(samples[i]); //Step 2: for each sample, get its amplitude's absolute value.
        
        // Step 3: for each sample's absolute value, run it through a simple low-pass filter
        // Begin low-pass filter
        currentFilteredValueOfSampleAmplitude = LOWPASSFILTERTIMESLICE * absoluteValueOfSampleAmplitude + (1.0 - LOWPASSFILTERTIMESLICE) * previousFilteredValueOfSampleAmplitude;
        previousFilteredValueOfSampleAmplitude = currentFilteredValueOfSampleAmplitude;
        Float32 amplitudeToConvertToDB = currentFilteredValueOfSampleAmplitude;
        // End low-pass filter
        
        Float32 sampleDB = amplitudeToConvertToDB /2500;//20.0*log10(amplitudeToConvertToDB) + DBOFFSET;
        // Step 4: for each sample's filtered absolute value, convert it into decibels
        // Step 5: for each sample's filtered absolute value in decibels, add an offset value that normalizes the clipping point of the device to zero.
        
        if((sampleDB == sampleDB) && (sampleDB != -DBL_MAX)) { // if it's a rational number and isn't infinite
            
            if(sampleDB > peakValue) peakValue = sampleDB; // Step 6: keep the highest value you find.
            decibels = peakValue; // final value
        }
    }
    return decibels;
}

////////////////////////////////////////////////////////
// get mean volumn
static inline float getMeanVolumeFloat32( Float32 * vector , int length ) {
    
    
    // get average input volume level for meter display
    // by calculating log of mean volume of the buffer
    // and displaying it to the screen
    // (note: there's a vdsp function to do this but it works on float samples
    
    int sum;
    int i;
    int averageVolume;
    float logVolume;
    
    
    sum = 0;
    for ( i = 0; i < length ; i++ ) {
        sum += abs(vector[i]);
    }
    
    averageVolume = sum / length;
    
    //    printf("\naverageVolume before scale = %lu", averageVolume );
    
    // now convert to logarithm and scale log10(0->32768) into 0->1 for display
    
    
    logVolume = log10f( (float) averageVolume );
    logVolume = logVolume / log10(32768);
    
    return (logVolume);
    
}

////////////////////////////////////////////////////////
// convert sample vector from SInt16 to fixed point 8.24
static inline void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt32) (source[i] << 9);
        if(source[i] < 0) {
            target[i] |= 0xFF000000;
        }
        else {
            target[i] &= 0x00FFFFFF;
        }
    }
}

////////////////////////////////////////////////////////
// generic error handler - if err is nonzero, prints error message and exits program.
static inline void checkStatus(OSStatus error, const char *operation) {
	if (error == noErr) return;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
	
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
	
	exit(1);
}

static inline void checkError(NSError*err, const char *operation)  {
    if (err) {
        fprintf(stderr, "Error: %s (%s)\n", operation, [[[err userInfo] description] UTF8String]);
        
        exit(1);
    }
}

////////////////////////////////////////////////////////
// mute audio data
static inline void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}

static inline void printASBD(AudioStreamBasicDescription asbd) {
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
