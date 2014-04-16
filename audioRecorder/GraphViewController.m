//
//  ViewController.m
//  audio
//
//  Created by Hai Le on 7/1/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "GraphViewController.h"
#import "AMGraphView.h"
#import "AudioController.h"

@interface GraphViewController () {
    AudioController *_audioController;
}

@end

@implementation GraphViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _audioController = [AudioController sharedInstance];
    
    [self startDrawing];
    
    [waveView setMinVal:0 maxVal:180];
}

- (void)waveViewUpdate{
    float lpf = _audioController.lpf;
    float hpf = _audioController.hpf;
    float bpf = _audioController.bpf;
    [waveView addX:hpf+lpf+bpf y:bpf+lpf z:lpf];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)startDrawing {
    if (![timer isValid]) {
        timer=[NSTimer scheduledTimerWithTimeInterval:0.015 target:self selector:@selector(waveViewUpdate) userInfo:nil repeats:YES];
    }
}

- (void)stopDrawing {
    [timer invalidate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopDrawing];
}

- (void)viewWillAppear:(BOOL)animated {
    [self startDrawing];
}


@end
