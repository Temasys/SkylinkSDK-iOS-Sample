//
//  TEMRichVideoView.m
//  SampleApp
//
//  Created by macbookpro on 07/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import "TEMRichVideoView.h"

#import "TEMProgressView.h"

#define LABEL_HEIGHT 21

@interface TEMRichVideoView ()

@property(nonatomic, weak) TEMProgressView* progressView;

@end

@implementation TEMRichVideoView

static void init(TEMRichVideoView *self, UIView *renderView) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, LABEL_HEIGHT)];
    label.textColor = [UIColor blueColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 1;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.translatesAutoresizingMaskIntoConstraints = YES;
    [self insertSubview:label aboveSubview:renderView];
    self.lblTitle = label;
}

- (id)initWithFrame:(CGRect)frame videoView:(UIView*)videoView {
    self = [super initWithFrame:frame videoView:videoView];
    if (self) {
        init(self, videoView);
        _isEnabled = TRUE;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *renderSurface = [self getRenderSurface];
    self.lblTitle.frame = CGRectMake(renderSurface.frame.origin.x, renderSurface.frame.origin.y, renderSurface.frame.size.width, LABEL_HEIGHT);
    self.progressView.frame = CGRectMake(self.lblTitle.frame.origin.x, CGRectGetMaxY(self.lblTitle.frame), self.lblTitle.frame.size.width, self.lblTitle.frame.size.height);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addProgressView {
    // Listen to the 'SKYLINKFileProgress' Notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotProgress:) name:@"SKYLINKFileProgress" object:nil];
    TEMProgressView *progressView = [[TEMProgressView alloc] initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, CGRectGetMaxY(self.lblTitle.frame), self.lblTitle.frame.size.width, self.lblTitle.frame.size.height)];
    [self insertSubview:progressView aboveSubview:self.lblTitle];
    self.progressView = progressView;
}

- (void)removeProgressView {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.progressView removeFromSuperview];
    self.progressView = nil;
}

#pragma mark - Properties

- (void)setIsEnabled:(BOOL)isEnabled {
    if (_isEnabled != isEnabled) {
        _isEnabled = isEnabled;
        if (isEnabled) {
            [self getTouchSurface].alpha = 1.0;
            [self getTouchSurface].backgroundColor = [UIColor clearColor];
        } else {
            [self getTouchSurface].alpha = 0.5;
            [self getTouchSurface].backgroundColor = [UIColor lightGrayColor];
        }
    }
}

- (void)setIsRemote:(BOOL)isRemote {
    if (_isRemote != isRemote) {
        _isRemote = isRemote;
        if (isRemote)
            [self getRenderSurface].transform = CGAffineTransformMakeScale(-1, 1);
    }
}

- (NSString*)title {
    return self.lblTitle.text;
}

- (void)setTitle:(NSString *)_title {
    self.lblTitle.text = _title;
}

#pragma mark - Private

/**
 @discussion Update progress bar upon getting 'SKYLINKFileProgress' Notification.
 */
- (void)gotProgress:(NSNotification*)notification {
    if ([self.ID caseInsensitiveCompare:[notification.userInfo objectForKey:@"peerId"]] == NSOrderedSame)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setPercentage:[[notification.userInfo objectForKey:@"percentage"] floatValue]];
        });
}

@end
