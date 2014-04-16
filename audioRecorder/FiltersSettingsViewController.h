//
//  FiltersSettingsViewController.h
//  audioRecorder
//
//  Created by Hai Le on 8/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMGraphView;

@interface FiltersSettingsViewController : UIViewController {
    // High Pass
    IBOutlet AMGraphView* waveViewHP;
    IBOutlet UIView *colorViewHP;
    IBOutlet UISlider *RSliderHP;
    IBOutlet UISlider *BSliderHP;
    IBOutlet UISlider *GSliderHP;
    IBOutlet UILabel *cutOffLabelHP;
    IBOutlet UIStepper *stepperHP;
    
    // Band Pass
    IBOutlet AMGraphView* waveViewBP;
    IBOutlet UIView *colorViewBP;
    IBOutlet UISlider *RSliderBP;
    IBOutlet UISlider *BSliderBP;
    IBOutlet UISlider *GSliderBP;
    IBOutlet UILabel *cutOffLabelBP;
    IBOutlet UILabel *BWLabelBP;
    IBOutlet UIStepper *stepperBP;
    IBOutlet UIStepper *BWStepperBP;
    
    // Low Pass
    IBOutlet AMGraphView* waveView;
    IBOutlet UIView *colorView;
    IBOutlet UISlider *RSlider;
    IBOutlet UISlider *BSlider;
    IBOutlet UISlider *GSlider;
    IBOutlet UILabel *cutOffLabel;
    IBOutlet UIStepper *stepper;
}

@end
