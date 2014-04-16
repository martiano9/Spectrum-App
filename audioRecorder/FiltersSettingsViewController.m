//
//  FiltersSettingsViewController.m
//  audioRecorder
//
//  Created by Hai Le on 8/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "FiltersSettingsViewController.h"
#import "AudioController.h"
#import "AMGraphView.h"
#import "UIColor+Expanded.h"

@interface FiltersSettingsViewController () {
    AudioController *_audioController;
    NSTimer *_timer;
}

@end

@implementation FiltersSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioController = [AudioController sharedInstance];
    [self startDrawing];
 
    [waveViewHP setMinVal:0 maxVal:75];
    
    [waveViewBP setMinVal:0 maxVal:75];
    
    [waveView setMinVal:0 maxVal:75];
}

- (void)waveViewUpdate{
    [waveViewHP addX:_audioController.hpf y:0 z:0];
    [waveViewBP addX:0 y:_audioController.bpf z:0];
    [waveView addX:0 y:0 z:_audioController.lpf];
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
    _audioController.hpGraphColor = [UIColor colorWithRed:RSliderHP.value green:GSliderHP.value blue:BSliderHP.value alpha:1];
    _audioController.bpGraphColor = [UIColor colorWithRed:RSliderBP.value green:GSliderBP.value blue:BSliderBP.value alpha:1];
    _audioController.lpGraphColor = [UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [self startDrawing];
    // Display color view
    [colorViewHP setBackgroundColor:_audioController.hpGraphColor];
    
    // Set value for sliders
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [colorViewHP.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    RSliderHP.value = red;
    BSliderHP.value = blue;
    GSliderHP.value = green;
    
    // Set value for stepper
    stepperHP.value = _audioController.hpfFreq1;
    cutOffLabelHP.text = [NSString stringWithFormat:@"%d",(int)stepperHP.value] ;
    
    // Band Pass
    // Display color view
    [colorViewBP setBackgroundColor:_audioController.bpGraphColor];
    
    // Set value for sliders
    red = 0.0; green = 0.0; blue = 0.0; alpha =0.0;
    [colorViewBP.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    RSliderBP.value = red;
    BSliderBP.value = blue;
    GSliderBP.value = green;
    
    // Set value for stepper
    stepperBP.value = _audioController.bpfFreq1;
    cutOffLabelBP.text = [NSString stringWithFormat:@"%d",(int)stepperBP.value] ;
    
    BWStepperBP.value = _audioController.bpfFreq2;
    BWLabelBP.text = [NSString stringWithFormat:@"%d",(int)BWStepperBP.value] ;
    
    // Low Pass
    // Display color view
    [colorView setBackgroundColor:_audioController.lpGraphColor];
    
    // Set value for sliders
    red = 0.0; green = 0.0; blue = 0.0; alpha =0.0;
    [colorView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    RSlider.value = red;
    BSlider.value = blue;
    GSlider.value = green;
    
    // Set value for stepper
    stepper.value = _audioController.lpfFreq1;
    cutOffLabel.text = [NSString stringWithFormat:@"%d",(int)stepper.value] ;

}

- (void)updateColorHP {
    _audioController.hpGraphColor = [UIColor colorWithRed:RSliderHP.value green:GSliderHP.value blue:BSliderHP.value alpha:1];
}

- (void)updateColorBP {
    _audioController.bpGraphColor = [UIColor colorWithRed:RSliderBP.value green:GSliderBP.value blue:BSliderBP.value alpha:1];
}
- (void)updateColorLP {
    _audioController.lpGraphColor = [UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1];
}

#pragma Actions

- (IBAction)RBGChangedHP:(id)sender {
    [colorViewHP setBackgroundColor:[UIColor colorWithRed:RSliderHP.value green:GSliderHP.value blue:BSliderHP.value alpha:1]];
    [self updateColorHP];
    [waveViewHP setNeedUpdate];
}

- (IBAction)CutoffValueChangedHP:(UIStepper *)sender {
    double value = [sender value];
    
    [cutOffLabelHP setText:[NSString stringWithFormat:@"%d", (int)value]];
    _audioController.hpfFreq1 = sender.value;
}

- (IBAction)RBGChangedBP:(id)sender {
    [colorViewBP setBackgroundColor:[UIColor colorWithRed:RSliderBP.value green:GSliderBP.value blue:BSliderBP.value alpha:1]];
    [self updateColorBP];
    [waveViewBP setNeedUpdate];
}

- (IBAction)CutoffValueChangedBP:(UIStepper *)sender {
    double value = [sender value];
    
    [cutOffLabelBP setText:[NSString stringWithFormat:@"%d", (int)value]];
    _audioController.bpfFreq1 = sender.value;
}

- (IBAction)BWValueChangedBP:(UIStepper *)sender {
    double value = [sender value];
    
    [BWLabelBP setText:[NSString stringWithFormat:@"%d", (int)value]];
    _audioController.bpfFreq2 = sender.value;
}

- (IBAction)RBGChanged:(id)sender {
    [colorView setBackgroundColor:[UIColor colorWithRed:RSlider.value green:GSlider.value blue:BSlider.value alpha:1]];
    [self updateColorLP];
    [waveView setNeedUpdate];
}

- (IBAction)CutoffValueChanged:(UIStepper *)sender {
    double value = [sender value];
    
    [cutOffLabel setText:[NSString stringWithFormat:@"%d", (int)value]];
    _audioController.lpfFreq1 = sender.value;
}


@end
