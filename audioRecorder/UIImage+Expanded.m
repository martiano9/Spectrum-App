//
//  UIImage+Expanded.m
//  audioRecorder
//
//  Created by Hai Le on 14/5/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "UIImage+Expanded.h"

@implementation UIImage (Expanded)

+ (UIImage *)whiteCircle {
    static UIImage *blueCircle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(15.f, 15.f), NO, 0.0f);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        
        CGRect rect = CGRectMake(0, 0, 15, 15);
        CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextFillEllipseInRect(ctx, rect);
        
        CGContextRestoreGState(ctx);
        blueCircle = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    });
    return blueCircle;
}

@end
