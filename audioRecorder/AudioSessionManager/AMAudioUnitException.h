//
//  AMAudioUnitException.h
//  audio
//
//  Created by Hai Le on 9/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AMAudioUnitException : NSObject

#define AMAudioThrowIfErr(err) { AMAudioThrow(err, __PRETTY_FUNCTION__, __LINE__); }

void AMAudioThrow(OSStatus errCode, const char *functionInfo, int lineNumber);
const char* AMAudioGetErrorStringFromOSStatus(OSStatus error);

@end
