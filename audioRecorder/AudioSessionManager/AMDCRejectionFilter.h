//
//  AMDCRejectionFilter.h
//  audio
//
//  Created by Hai Le on 11/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMDCRejectionFilter : NSObject

-(void) inplaceFilter:(Float32*) ioData frameCount:(UInt32) numFrames;

@end
