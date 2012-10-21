// DirectionSearchView.m
// 
// Copyright (c) 2012 415Bike
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DirectionSearchView.h"

@interface DirectionSearchView () <UITextFieldDelegate>
@property (readwrite, nonatomic, strong) UITextField *fromTextField;
@property (readwrite, nonatomic, strong) UITextField *toTextField;
@end

@implementation DirectionSearchView

- (void)commonInit {
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
    
    self.backgroundColor = [UIColor clearColor];
    
    self.fromTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.fromTextField.delegate = self;
    self.fromTextField.text = NSLocalizedString(@"Current Location", nil);
    self.fromTextField.textColor = [UIColor colorWithRed:0.427 green:0.739 blue:0.956 alpha:1.000];
    self.fromTextField.returnKeyType = UIReturnKeyNext;
    self.fromTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.fromTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.fromTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fromTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.fromTextField.font = [UIFont boldSystemFontOfSize:self.fromTextField.font.pointSize];
    [self addSubview:self.fromTextField];
    
    self.toTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.toTextField.delegate = self;
    self.toTextField.placeholder = NSLocalizedString(@"Destination", nil);
    self.toTextField.returnKeyType = UIReturnKeyRoute;
    self.toTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.toTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.toTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.toTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.toTextField.textColor = [UIColor whiteColor];
    self.toTextField.enablesReturnKeyAutomatically = YES;
    [self addSubview:self.toTextField];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    [self setHidden:hidden];
}

#pragma mark - UIView

- (void)layoutSubviews {
    self.fromTextField.frame = CGRectIntegral(CGRectInset(CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height / 2.0f), 12.0f, 8.0f));
    self.toTextField.frame = CGRectIntegral(CGRectInset(CGRectMake(0.0f, self.frame.size.height / 2.0f, self.frame.size.width, self.frame.size.height / 2.0f), 12.0f, 8.0f));
}

- (void)drawRect:(CGRect)rect {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSArray *newGradientColors = @[
        (id)[[UIColor colorWithWhite:0.900 alpha:0.900] CGColor],

        (id)[[UIColor colorWithWhite:0.200 alpha:0.900] CGColor],
        (id)[[UIColor colorWithWhite:0.298 alpha:0.900] CGColor]
    ];
    CGFloat newGradientLocations[] = {0.0, 0.025, 1.0};
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)newGradientColors, newGradientLocations);
    CGColorSpaceRelease(colorSpace);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *border = [UIColor darkGrayColor];
    
    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10.0f];
    CGContextSaveGState(context);
    {
        [roundedRectanglePath addClip];
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0, 0.5), CGPointMake(0.0, rect.size.height-0.5), 0);
    }
    CGContextRestoreGState(context);
    [border setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];
    
    CGPathRef linePath = CGPathCreateWithRect(CGRectIntegral(CGRectMake(0.0f, CGRectGetMidY(self.bounds), self.bounds.size.width, 0.0f)), NULL);
    CGContextAddPath(context, linePath);
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(context, 0.5f);
    CGContextStrokePath(context);    
}

#pragma mark - UIResponder

- (BOOL)becomeFirstResponder {
    return [self.toTextField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.fromTextField]) {
        [self.toTextField becomeFirstResponder];
    } else {
        [self.delegate searchViewDidRoute:self];
        [self.toTextField resignFirstResponder];
    }
    
    return YES;
}

@end
