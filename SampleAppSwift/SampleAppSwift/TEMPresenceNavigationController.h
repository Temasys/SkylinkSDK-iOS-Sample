//
//  TEMPresenceNavigationController.h
//  TEM
//
//  Created by macbookpro on 02/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TEMPresenceNavigationController : UINavigationController

@property (nonatomic, unsafe_unretained) BOOL minimize;

- (CGFloat)getMinimizedY;
- (void)refurbish:(BOOL)minimize;

@end
