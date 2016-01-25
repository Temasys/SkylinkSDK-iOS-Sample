//
//  TEMVideoView.m
//  SampleApp
//
//  Created by macbookpro on 07/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "TEMVideoView.h"

@interface TEMVideoView () {
    CGSize renderSize;
}

@property(nonatomic, weak) UIView* renderView;
@property(nonatomic, weak) UIButton* glassButton;

@end

@implementation TEMVideoView

static void init(TEMVideoView *videoView, UIView *renderView) {
    renderView.frame = videoView.bounds;
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderView.translatesAutoresizingMaskIntoConstraints = YES;
    [videoView addSubview:renderView];
    videoView.renderView = renderView;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, videoView.bounds.size.width, videoView.bounds.size.height);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.translatesAutoresizingMaskIntoConstraints = YES;
    [button addTarget:videoView action:@selector(videoViewIsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [videoView addSubview:button];
    videoView.glassButton = button;
}

- (id)initWithFrame:(CGRect)frame videoView:(UIView*)renderView {
    self = [super initWithFrame:frame];
    if (self) {
        init(self, renderView);
        renderSize = CGSizeZero;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_renderView && (renderSize.height > 0 && renderSize.width > 0)) {
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        CGSize aspectRatio = CGSizeEqualToSize(renderSize, CGSizeZero) ? defaultAspectRatio : renderSize;
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, self.bounds);
        self.renderView.frame = self.glassButton.frame = videoFrame;
    }
}

#pragma mark - public methods

- (void)layoutSubviews:(CGSize)size {
    renderSize = CGSizeEqualToSize(size, CGSizeZero) ? renderSize : size;
    [self setNeedsLayout];
}

- (UIView*)getRenderSurface {
    return self.renderView;
}

- (UIView*)getTouchSurface {
    return self.glassButton;
}

#pragma mark - IBAction

- (IBAction)videoViewIsTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(videoViewIsTapped:)])
        [self.delegate videoViewIsTapped:self];
}

@end
