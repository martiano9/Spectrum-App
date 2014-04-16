//
//  ViewController.h
//  audio
//
//  Created by Hai Le on 7/1/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMSlideMenuMainViewController.h"

@class AMGraphView;

@interface GraphViewController : UIViewController {
    IBOutlet AMGraphView* waveView;
    NSTimer *timer;
}

- (void)startDrawing;
- (void)stopDrawing;

@end
