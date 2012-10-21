// DirectionStepsView.m
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

#import <CoreText/CoreText.h>
#import "DirectionStepsView.h"
#import "BButton.h"
#import "TTTLocationFormatter.h"
#import "TTTAttributedLabel.h"

#import "GoogleMapsAPIClient.h"

@interface DirectionStepsView ()
@property (nonatomic) NSString *title;
@end

@implementation DirectionStepsView

- (void)commonInit {
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
    
    self.backgroundColor = [UIColor clearColor];
    
    self.titleLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.titleLabel];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.distanceLabel.backgroundColor = [UIColor clearColor];
    self.distanceLabel.textColor = [UIColor whiteColor];
    self.distanceLabel.textAlignment = NSTextAlignmentCenter;
    self.distanceLabel.numberOfLines = 1;
    self.distanceLabel.font = [UIFont systemFontOfSize:12.0f];
    self.distanceLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.distanceLabel];
    
    self.previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.previousButton setTitle:@"◄" forState:UIControlStateNormal];
    [self.previousButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.previousButton.showsTouchWhenHighlighted = YES;
    [self.previousButton addTarget:self action:@selector(previous:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.previousButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton setTitle:@"►" forState:UIControlStateNormal];
    [self.nextButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.nextButton.showsTouchWhenHighlighted = YES;
    [self.nextButton addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.nextButton];
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

- (void)setRoute:(GoogleMapsDirectionsRoute *)route {
    NSParameterAssert(route);
    NSParameterAssert([route.steps count] > 0);
    
    _route = route;
    
    self.currentStep = [route.steps objectAtIndex:0];
}

- (void)setCurrentStep:(GoogleMapsDirectionsStep *)currentStep {
    static TTTLocationFormatter *_locationFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _locationFormatter = [[TTTLocationFormatter alloc] init];
        _locationFormatter.unitSystem = TTTImperialSystem;
    });
    
    if ([_currentStep isEqual:currentStep]) {
        return;
    }
    
    _currentStep = currentStep;
    
    NSUInteger idx = [self.route.steps indexOfObject:self.currentStep];
    self.title = self.currentStep.instructions;
    self.distanceLabel.text = [_locationFormatter stringFromDistance:self.currentStep.distance];
    self.previousButton.enabled = idx > 0;
    self.nextButton.enabled = idx < [self.route.steps count] - 1;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setTitle:(NSString *)title {
    NSArray *tokens = [title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    @autoreleasepool {
        __block BOOL isWithinTag = NO;
        __block BOOL isAtDivTag = NO;
        [tokens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *token = (NSString *)obj;
            
            if ([token hasSuffix:@"<div"]) {
                token = [token substringToIndex:[token rangeOfString:@"<div"].location];
                isAtDivTag = YES;
            }
            
            if (isWithinTag || [token hasPrefix:@"<b>"]) {
                if ([token hasPrefix:@"<b>"]) {
                    token = [token substringWithRange:NSMakeRange(3, [token length] - 3)];
                }
                
                if ([token hasSuffix:@"</b>"]) {
                    token = [token substringWithRange:NSMakeRange(0, [token length] - 4)];
                    isWithinTag = NO;
                } else {
                    isWithinTag = YES;
                }
                [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[token stringByAppendingString:@" "] attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0f]}]];
            } else {
                [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[token stringByAppendingString:@" "]]];
            }
            
            if (isAtDivTag) {
                *stop = YES;
            }
            
        }];
        [mutableAttributedString addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(id)[[UIColor whiteColor] CGColor] range:NSMakeRange(0, mutableAttributedString.length)];
        
        CTTextAlignment alignment = kCTCenterTextAlignment;
        CTParagraphStyleSetting paragraphStyles[1] = {
            {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void *)&alignment}
        };
        
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 1);
        [mutableAttributedString addAttribute:(NSString *)kCTParagraphStyleAttributeName value:(__bridge id)paragraphStyle range:NSMakeRange(0, mutableAttributedString.length)];
        CFRelease(paragraphStyle);
    }
    
    self.titleLabel.text = mutableAttributedString;
}

#pragma mark - IBAction

- (void)previous:(id)sender {
    NSUInteger idx = [self.route.steps indexOfObject:self.currentStep];
    if (idx > 0) {
        self.currentStep = [self.route.steps objectAtIndex:idx - 1];
    }
}

- (void)next:(id)sender {
    NSUInteger idx = [self.route.steps indexOfObject:self.currentStep];
    if (idx < [self.route.steps count] - 1) {
        self.currentStep = [self.route.steps objectAtIndex:idx + 1];
    }
}

#pragma mark - UIView

- (void)layoutSubviews {
    self.previousButton.frame = CGRectMake(3.0f, 5.0f, 37.0f, 44.0f);
    self.nextButton.frame = CGRectMake(self.bounds.size.width - 40.0f, 5.0f, 37.0f, 44.0f);
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.previousButton.frame), 0.0f, self.bounds.size.width - 80.0f, 40.0f);
    self.distanceLabel.frame = CGRectMake(CGRectGetMaxX(self.previousButton.frame), 40.0f, self.bounds.size.width - 80.0f, 15.0f);
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef c = UIGraphicsGetCurrentContext();
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10.0f];
    
    [[[UIColor darkGrayColor] colorWithAlphaComponent:0.9] setFill];
    [[UIColor darkGrayColor] setStroke];
    CGContextAddPath(c, [bezierPath CGPath]);
    CGContextFillPath(c);
    CGContextAddPath(c, [bezierPath CGPath]);
    
    CGContextSetLineWidth(c, 1.0f);
    CGContextStrokePath(c);
}


@end
