//
//  TEMProgressView.m
//  ProgressView
//
//  Created by macbookpro on 09/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import "TEMProgressView.h"

@interface TEMProgressView ()

@property (nonatomic, weak) UILabel *progressLabel;
@property (nonatomic, weak) UIProgressView *progressView;

@end

@implementation TEMProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:progressView];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|"
                                                                       options:0
                                                                       metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(progressView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressView]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(progressView)]];
        self.progressView = progressView;
        
        UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        progressLabel.backgroundColor = [UIColor clearColor];
        progressLabel.textAlignment = NSTextAlignmentCenter;
        progressLabel.textColor = [UIColor blackColor];
        [self addSubview:progressLabel];
        progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressLabel]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(progressLabel)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressLabel]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(progressLabel)]];
        self.progressLabel = progressLabel;
    }
    return self;
}

- (void)setPercentage:(CGFloat)percent
{
    [self.progressView setProgress:percent animated:YES];
    self.progressLabel.text = [NSString stringWithFormat:@"%i %%", (int)(percent*100)];
}

@end
