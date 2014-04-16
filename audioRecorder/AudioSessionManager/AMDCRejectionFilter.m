//
//  AMDCRejectionFilter.m
//  audio
//
//  Created by Hai Le on 11/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMDCRejectionFilter.h"

const Float32 kDefaultPoleDist = 0.975f;

@interface AMDCRejectionFilter (){
    Float32	mY1;
    Float32 mX1;
}
@end

@implementation AMDCRejectionFilter

-(id)init {
    if (self = [super init]) {
        mX1 = 0.0;
        mY1 = 0.0f;
    }
    return self;
}

-(void) inplaceFilter:(Float32*) ioData frameCount:(UInt32) numFrames
{
	for (UInt32 i=0; i < numFrames; i++)
	{
        Float32 xCurr = ioData[i];
		ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1);
        mX1 = xCurr;
        mY1 = ioData[i];
	}
}

@end
