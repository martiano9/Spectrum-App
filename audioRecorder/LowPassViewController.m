//
//  LowPassViewController.m
//  audioRecorder
//
//  Created by Hai Le on 27/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "LowPassViewController.h"
#import "AudioController.h"
#import "AMGraphView.h"

@interface LowPassViewController () {
    AudioController *_audioController;
    NSTimer *_timer;
}
@end

@implementation LowPassViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioController = [AudioController sharedInstance];
    
    [self startDrawing];
    
    [waveView setMinVal:0 maxVal:75];
}

- (void)waveViewUpdate{
    float lpf = _audioController.lpf;
    [waveView addX:0 y:0 z:lpf];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)startDrawing {
    if (![_timer isValid]) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.015 target:self selector:@selector(waveViewUpdate) userInfo:nil repeats:YES];
    }
}

- (void)stopDrawing {
    [_timer invalidate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopDrawing];
    _audioController.lpGraphColor = [UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [self startDrawing];
    // Display color view
    [colorView setBackgroundColor:_audioController.lpGraphColor];
    
    // Set value for sliders
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [colorView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    RSlider.value = red;
    BSlider.value = blue;
    GSlider.value = green;
    
    // Set value for stepper
    stepper.value = _audioController.lpfFreq1;
    cutOffLabel.text = [NSString stringWithFormat:@"%d",(int)stepper.value] ;
}

- (void)updateColor {
    _audioController.lpGraphColor = [UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1];
}

#pragma Actions

- (IBAction)RBGChanged:(id)sender {
    [colorView setBackgroundColor:[UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1]];
    [self updateColor];
    [waveView setNeedUpdate];
}

- (IBAction)CutoffValueChanged:(UIStepper *)sender {
    double value = [sender value];
    
    [cutOffLabel setText:[NSString stringWithFormat:@"%d", (int)value]];
    _audioController.lpfFreq1 = sender.value;
}

@end
