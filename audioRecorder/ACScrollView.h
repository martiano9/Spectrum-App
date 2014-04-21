//
//  ACScrollView.h
//  AmazingControls
//
//  Created by Hai Le on 21/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACScrollView : UIScrollView {
    CGSize _keyboardSize;
    CGPoint _offset;
    int _activeTextFieldIndex;
}

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *prevBarButton;
@property (nonatomic, strong) UIBarButtonItem *nextBarButton;

@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, strong) NSMutableArray *textFieldArray;

@end
