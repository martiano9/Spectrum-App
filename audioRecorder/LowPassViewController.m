//
//  LowPassViewController.m
//  audioRecorder
//
//  Created by Hai Le on 27/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "LowPassViewController.h"
#import "AudioController.h"
#import "UIColor+Expanded.h"
#import "UIImage+Expanded.h"
#import "ACTextField.h"
#import "ACScrollView.h"

@interface LowPassViewController () <UITextFieldDelegate, AudioControllerDelegate> {
    AudioController *_audioController;
}
@end

@implementation LowPassViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioController = [AudioController sharedInstance];
    _audioController.delegate = self;
    
    // Wave view
    waveView.plotType        = EZPlotTypeRolling;
    waveView.shouldFill      = YES;
    waveView.gain            = _audioController.lowPassGain;
    waveView.color           = _audioController.lowPassGraphColor;
    waveView.backgroundColor = [UIColor colorWithWhite:.3 alpha:1];
    waveView.gain            = _audioController.lowPassGain;
    
    // Display color view
    [colorView setBackgroundColor:_audioController.lowPassGraphColor];
    
    // Set value for sliders
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [colorView.backgroundColor getRed:&red
                                green:&green
                                 blue:&blue
                                alpha:&alpha];
    RSlider.value = red;
    BSlider.value = blue;
    GSlider.value = green;
    
    // Textfield
    [cutOffTextField setDelegate:self];
    [cutOffTextField setPlaceholderColor:[UIColor colorWithHexString:@"#16A085"]];
    [cutOffTextField setFloatingLabelActiveTextColor:[UIColor colorWithHexString:@"#1ABC9C"]];
    
    [noiseFloorTextField setDelegate:self];
    [noiseFloorTextField setPlaceholderColor:[UIColor colorWithHexString:@"#16A085"]];
    [noiseFloorTextField setFloatingLabelActiveTextColor:[UIColor colorWithHexString:@"#1ABC9C"]];
    
    [filterOrderTextField setDelegate:self];
    [filterOrderTextField setPlaceholderColor:[UIColor colorWithHexString:@"#16A085"]];
    [filterOrderTextField setFloatingLabelActiveTextColor:[UIColor colorWithHexString:@"#1ABC9C"]];
    [filterOrderTextField setType:ACPickerFieldType];
    [filterOrderTextField setPickerData:[NSArray arrayWithObjects:
                                         @"2nd Order",
                                         @"3rd Order",
                                         @"4th Order",
                                         @"5th Order",
                                         @"6th Order",
                                         @"7th Order",
                                         @"8th Order",
                                         @"9th Order",
                                         @"10th Order",nil]];
    [filterOrderTextField setPickerIndex:_audioController.lowPassFilterOrder-2];
    
    [waveTypeTextField setDelegate:self];
    [waveTypeTextField setPlaceholderColor:[UIColor colorWithHexString:@"#16A085"]];
    [waveTypeTextField setFloatingLabelActiveTextColor:[UIColor colorWithHexString:@"#1ABC9C"]];
    [waveTypeTextField setType:ACPickerFieldType];
    [waveTypeTextField setPickerData:[NSArray arrayWithObjects:@"Buffer",@"Rolling",nil]];
    [waveTypeTextField setPickerIndex:1];
    
    // Set value text field
    cutOffTextField.text = [NSString stringWithFormat:@"%.0f",_audioController.lowPassCutOff];
    noiseFloorTextField.text = [NSString stringWithFormat:@"%.0f",_audioController.lowPassGain];
    
    // Change thumb size
    UIImage *thumbImage = [UIImage whiteCircle];
    [RSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [BSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [GSlider setThumbImage:thumbImage forState:UIControlStateNormal];


}

- (void)viewWillDisappear:(BOOL)animated {
    _audioController.delegate = nil;
}

#pragma Actions

- (IBAction)RBGChanged:(id)sender {
    UIColor *color = [UIColor colorWithRed:RSlider.value
                                     green:GSlider.value
                                      blue:BSlider.value
                                     alpha:1];
    [self changeColor:color];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    ACTextField* foo = (ACTextField*)textField;
    float value;
    if (textField.text.length == 0) {
        value = 50;
        textField.text = [NSString stringWithFormat:@"%.0f",value];
    } else {
        value = [textField.text floatValue];
    }
    
    if (textField == cutOffTextField) {
        _audioController.lowPassCutOff = value;
        [_audioController resetLowPassFilter];
    } else if (textField == noiseFloorTextField) {
        _audioController.lowPassGain = value;
        waveView.gain = value;
    } else if (textField == filterOrderTextField) {
        _audioController.lowPassFilterOrder = foo.pickerIndex + 2;
        [_audioController resetLowPassFilter];
    }
    else if (textField == waveTypeTextField) {
        waveView.shouldFill = foo.pickerIndex;
        waveView.plotType = foo.pickerIndex;
    }
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - AudioControllerDelegate

- (void)lowPassDidFinish:(float *)data withBufferSize:(UInt32)bufferSize{
    [waveView updateBuffer:data withBufferSize:bufferSize];
}

#pragma mark - Private Category

- (void)changeColor:(UIColor*)color {
    [colorView setBackgroundColor:color];
    _audioController.lowPassGraphColor = color;
    waveView.color = color;
}

@end
