//
//  ACScrollView.m
//  AmazingControls
//
//  Created by Hai Le on 21/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "ACScrollView.h"
#import "ACTextField.h"

CGFloat ACStatusBarHeight()
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

@interface ACScrollView ()

@end

@interface ACScrollView (Private)

- (void)commonInit;
- (id)getFirstResponderInView:(UIView*)view;
- (void)adjustScrollViewOffsetToCenterTextField:(UITextField *)textField;

@end

@interface ACScrollView (Toolbar)

- (void)initToolbar;
- (void)prevButtonTapped:(id)sender;
- (void)nextButtonTapped:(id)sender;
- (void)doneButtonTapped:(id)sender;

@end

@implementation ACScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Initialization code
        [self initToolbar];
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
//    [self initToolbar];
//    [self commonInit];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Category

- (void)commonInit {
    // Init text field array
    self.textFieldArray = [[NSMutableArray alloc] init];
    
    // Generate array elements
    [self generateTextFieldArrayInView:self];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

- (id)getFirstResponderInView:(UIView *)view {
    for(UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[ACTextField class]] && [subView isFirstResponder]) {
            return subView;
        }
    }
    return nil;
}

- (void)generateTextFieldArrayInView:(UIView*)view {
    int index = 0;
    if ([self.textFieldArray count] == 0) {
        for(UIView *subView in view.subviews) {
            if ([subView isKindOfClass:[ACTextField class]]) {
                ACTextField *textField = (ACTextField*)subView;
                [textField setInputAccessoryView:self.toolbar];
                [textField setTag:index];
                
                [self.textFieldArray addObject:textField];
                
                index++;
            }
        }
    }
}

- (void)adjustScrollViewOffsetToCenterTextField:(UITextField *)textField
{
    
    CGRect oldFrame = [self.superview convertRect:_activeTextField.frame fromView:self];
    
    float visibleScrollViewHeight = self.superview.bounds.size.height - _keyboardSize.height - self.frame.origin.y;
    
    float newPosY = (visibleScrollViewHeight-oldFrame.size.height)/2 + self.frame.origin.y;
    
    float scrollViewOffset = oldFrame.origin.y - newPosY;
    
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y+scrollViewOffset);
    }completion:NULL];
    
}

#pragma mark - UIKeyboard notifications

- (void)keyboardWillShow:(NSNotification*) notification {
    // Get default size from notification
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Get active text field
    self.activeTextField = [self getFirstResponderInView:self];
    
    // Calculate actual size of keyboard base on orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown)
        _keyboardSize = keyboardSize;
    else
        _keyboardSize = CGSizeMake(keyboardSize.height, keyboardSize.width);
    
   	// Save the current location so we can restore when keyboard is dismissed
	_offset = self.contentOffset;
	
    if (_activeTextField)
        [self adjustScrollViewOffsetToCenterTextField:_activeTextField];
    
}

- (void)keyboardWillHide:(NSNotification*) notification {
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _offset.y = 0.0;
        self.contentOffset = _offset;
    }completion:NULL];
}

#pragma mark - Toolbar Category

- (void)initToolbar {
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.frame = CGRectMake(0, 0, self.window.frame.size.width, 44.0f);
    // set style
    [self.toolbar setBarStyle:UIBarStyleDefault];
    [self.toolbar setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth)];
    
    self.prevBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:105
                                                                       target:self
                                                                       action:@selector(prevButtonTapped:)];
    
    self.nextBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:106
                                                                       target:self
                                                                       action:@selector(nextButtonTapped:)];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
    fixedSpace.width = 22.0;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(doneButtonTapped:)];
    
    NSArray *barButtonItems = @[self.prevBarButton,
                                fixedSpace,
                                self.nextBarButton,
                                flexibleSpace,
                                doneBarButton];
    
    _toolbar.items = barButtonItems;
}

- (void)prevButtonTapped:(id)sender {
    _activeTextFieldIndex --;
    if (_activeTextFieldIndex<0) {
        _activeTextFieldIndex = 0;
    }
    
    self.activeTextField = [self.textFieldArray objectAtIndex:_activeTextFieldIndex];
    [self adjustScrollViewOffsetToCenterTextField:_activeTextField];
}

- (void)nextButtonTapped:(id)sender {
    _activeTextFieldIndex ++;
    if(_activeTextFieldIndex == self.textFieldArray.count)
        _activeTextFieldIndex--;
    
    self.activeTextField = [self.textFieldArray objectAtIndex:_activeTextFieldIndex];
    [self adjustScrollViewOffsetToCenterTextField:_activeTextField];
}

- (void)doneButtonTapped:(id)sender {
    [self endEditing:YES];
}

#pragma mark - Public Category

- (void)setActiveTextField:(UITextField *)activeTextField {
    if (activeTextField != _activeTextField && activeTextField != nil) {
        _activeTextFieldIndex = [self.textFieldArray indexOfObject:activeTextField];
        if (_activeTextFieldIndex != -1) {
            _activeTextField = activeTextField;
            
            if(activeTextField) {
                if (![activeTextField isFirstResponder]) {
                    [activeTextField becomeFirstResponder];
                }
                
                [self.prevBarButton setEnabled:(_activeTextFieldIndex > 0)];
                [self.nextBarButton setEnabled:(_activeTextFieldIndex < [self.textFieldArray count] - 1)];
            }
        }
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
