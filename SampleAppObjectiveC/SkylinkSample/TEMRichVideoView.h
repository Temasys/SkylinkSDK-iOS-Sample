//
//  TEMRichVideoView.h
//  SampleApp
//
//  Created by macbookpro on 07/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

#import "TEMVideoView.h"

@interface TEMRichVideoView : TEMVideoView

@property(nonatomic, unsafe_unretained) BOOL isEnabled;
@property(nonatomic, unsafe_unretained) BOOL isRemote;

@property(nonatomic, copy) NSString *ID;
@property(nonatomic, weak) NSString *title;

@property(nonatomic, weak) UILabel* lblTitle;

- (id)initWithFrame:(CGRect)frame videoView:(UIView*)renderView;

- (void)addProgressView;
- (void)removeProgressView;

@end
