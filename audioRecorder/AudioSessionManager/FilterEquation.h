//
//  AMDigitalFilter.h
//  audio
//
//  Created by Hai Le on 17/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

#define filterMinOrder 1
#define filterMaxOrder 5
#define filterMaxCoeffCount (filterMaxOrder*2)

// List of Filter classes
typedef enum {
    ButterWorth
} FilterName;

typedef enum {
    LowPass,
    BandPass,
    HighPass
} FilterType;

@interface FilterEquation : NSObject {
    float xv[filterMaxCoeffCount+1];   // X coeffs of the difference equation defined for this filter
    float yv[filterMaxCoeffCount+1];   // Y coeffs of the difference equation defined for this filter
    
    float C;
    float D;
    float a[filterMaxCoeffCount+1];
    float b[filterMaxCoeffCount+1];
    
    FilterType _type;
    FilterName _name;
}

@property (nonatomic) float freq1;
@property (nonatomic) float freq2;
@property (nonatomic) float sampleFreq;
@property (nonatomic) float order;

- (id)initLowPass:(FilterName)name sampleRate:(float)sampleRate cutoffFrequency:(float)cutoff order:(int)order;
- (id)initHighPass:(FilterName)name sampleRate:(float)sampleRate cutoffFrequency:(float)cutoff order:(int)order;
- (id)initBandPass:(FilterName)name sampleRate:(float)sampleRate centerFrequency:(float)center bandWidth:(float)bw order:(int)order;

- (void)shiftY;
- (void)shiftX;
- (float)calculate:(float)value;


@end
