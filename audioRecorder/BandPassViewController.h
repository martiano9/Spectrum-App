//
//  BandPassViewController.h
//  audioRecorder
//
//  Created by Hai Le on 27/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMGraphView;

@interface BandPassViewController : UIViewController {
    IBOutlet AMGraphView* waveView;
    IBOutlet UIView *colorView;
    IBOutlet UISlider *RSlider;
    IBOutlet UISlider *BSlider;
    IBOutlet UISlider *GSlider;
    IBOutlet UILabel *cutOffLabel;
    IBOutlet UILabel *BWLabel;
    IBOutlet UIStepper *stepper;
    IBOutlet UIStepper *BWStepper;
}

@end
