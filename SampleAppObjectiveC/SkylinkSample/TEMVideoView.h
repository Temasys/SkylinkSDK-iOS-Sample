//
//  TEMVideoView.h
//  SampleApp
//
//  Created by macbookpro on 07/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TEMVideoView;

/**
 @discussion The delegate to handle touch events on the TEMVideoView.
 */
@protocol TEMVideoViewDelegate <NSObject>

@optional

/** Is triggered when a tap happens on the underlying render view.
 @param videoView The containing TEMVideoView object.
 */
- (void)videoViewIsTapped:(TEMVideoView*)videoView;

@end

/**
 @discussion A view designed to contain the render view from SKYLINKConnection.
 */
@interface TEMVideoView : UIView

/**
 @brief Delegate to handle touch events on the view.
 */
@property(nonatomic, weak) id<TEMVideoViewDelegate> delegate;

/** Initialize and return a newly allocated TEMVideoView object.
 @param frame Frame of the containing view
 @param renderView The contained view
 */
- (id)initWithFrame:(CGRect)frame videoView:(UIView*)renderView;

/** Send this message when the size of the contained view is changed.
 @param size New size of the contained view.
 */
- (void)layoutSubviews:(CGSize)size;

/** Return a reference to the contained view
 */
- (UIView*)getRenderSurface;

/** Return a UIView representing the touch surface.
 */
- (UIView*)getTouchSurface;

@end
