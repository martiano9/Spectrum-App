//
//  BandPassViewController.h
//  audioRecorder
//
//  Created by Hai Le on 27/2/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EZAudioPlot;
@class AMGraphView;
@class ACScrollView;
@class ACTextField;

@interface BandPassViewController : UIViewController {
    IBOutlet EZAudioPlot* waveView;
    IBOutlet UIView *colorView;
    IBOutlet UISlider *RSlider;
    IBOutlet UISlider *BSlider;
    IBOutlet UISlider *GSlider;
    
    IBOutlet ACTextField *cutOffTextField;
    IBOutlet ACTextField *bandwidthTextField;
    IBOutlet ACTextField *noiseFloorTextField;
    IBOutlet ACTextField *filterOrderTextField;
    IBOutlet ACTextField *waveTypeTextField;
    IBOutlet ACScrollView *scoller;
}

@end
