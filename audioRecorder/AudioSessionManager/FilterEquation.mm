//
//  AMDigitalFilter.m
//  audio
//
//  Created by Hai Le on 17/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "FilterEquation.h"
#import "Dsp.h"

@implementation FilterEquation

@synthesize freq1 = _freq1;
@synthesize freq2 = _freq2;
@synthesize sampleFreq = _sampleFreq;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)initLowPass:(FilterName)name sampleRate:(float)sampleRate cutoffFrequency:(float)cutoff order:(int)order {
    self = [super init];
    if (self) {
        _sampleFreq = sampleRate;
        _freq1 = cutoff;
        _order = order;
        _type = LowPass;
        _name = ButterWorth;
        
        [self calculateCoefficients];
    }
    return self;
}

- (id)initHighPass:(FilterName)name sampleRate:(float)sampleRate cutoffFrequency:(float)cutoff order:(int)order {
    self = [super init];
    if (self) {
        _sampleFreq = sampleRate;
        _freq1 = cutoff;
        _order = order;
        _type = LowPass;
        _name = ButterWorth;
        
        [self calculateCoefficients];
    }
    return self;
}

- (id)initBandPass:(FilterName)name sampleRate:(float)sampleRate centerFrequency:(float)center bandWidth:(float)bw order:(int)order {
    self = [super init];
    if (self) {
        _sampleFreq = sampleRate;
        _freq1 = center;
        _freq2 = bw;
        _order = order;
        _type = LowPass;
        _name = ButterWorth;
        
        [self calculateCoefficients];
    }
    return self;
}

- (void)calculateCoefficients {
    [self localReset];
    if (_name == ButterWorth && _type == LowPass) {
        Dsp::SimpleFilter <Dsp::Butterworth::LowPass <10> > lowpass;
        lowpass.setup (_order, _sampleFreq, _freq1);
        
        a[0] = lowpass[0].getA0();
        a[1] = lowpass[0].getA1();
        a[2] = lowpass[0].getA2();
        b[0] = lowpass[0].getB0();
        b[1] = lowpass[0].getB1();
        b[2] = lowpass[0].getB2();

    } else if(_name == ButterWorth && _type == BandPass) {
        Dsp::SimpleFilter <Dsp::Butterworth::BandPass <10> > bandpass;
        bandpass.setup(_order, _sampleFreq, _freq1, _freq2);
        
        a[0] = bandpass[0].getA0();
        a[1] = bandpass[0].getA1();
        a[2] = bandpass[0].getA2();
        b[0] = bandpass[0].getB0();
        b[1] = bandpass[0].getB1();
        b[2] = bandpass[0].getB2();
        
    } else if (_name == ButterWorth && _type == HighPass) {
        Dsp::SimpleFilter <Dsp::Butterworth::HighPass <10> > hipass;
        hipass.setup (_order, _sampleFreq, _freq1);
        
        a[0] = hipass[0].getA0();
        a[1] = hipass[0].getA1();
        a[2] = hipass[0].getA2();
        b[0] = hipass[0].getB0();
        b[1] = hipass[0].getB1();
        b[2] = hipass[0].getB2();
        
    }

}

- (void)setFreq1:(float)freq1 {
    _freq1 = freq1;
    [self calculateCoefficients];
}

- (void)setFreq2:(float)freq2 {
    _freq2 = freq2;
    [self calculateCoefficients];
}

// Shift the X values of an IIR or FIR filter
-(void)shiftX
{
    // Shift the xv
    for(int i=0; i<2; i++) {
        xv[i] = xv[i+1];
    }
}

// Shift the Y values of an IIR filter
-(void)shiftY
{
    // Shift the yv values
    for(int i=0; i<2; i++) {
        yv[i] = yv[i+1];
    }
}

- (float)calculate:(float)value {

    // Shift the xv and yv values
    [self shiftX];
    [self shiftY];
    
    int n = 2;
    
    // Insert the new value into the filter
    xv[n] = value;
    
    // Calculate the new output
    yv[n] = (b[0]*xv[n]) + (b[1]*xv[n-1]) + (b[2]*xv[n-2]) - (a[1]*yv[n-1]) - (a[2]*yv[n-2]);
    
    return  yv[n];
}

-(void)localReset
{
    for(int i=0; i<filterMaxCoeffCount+1; i++)
    {
        xv[i] = yv[i] = 0.0;
    }
}

@end
