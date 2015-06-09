//
//  TEMAppDelegate.h
//  TEM
//
//  Created by macbookpro on 14/10/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TEMRoomViewController;
@class SKYLINKConnectionConfig;

@interface TEMAppDelegate : UIResponder <UIApplicationDelegate>

@property (unsafe_unretained, nonatomic) BOOL isPad;
@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) TEMRoomViewController *roomViewController;
@property (strong, nonatomic) SKYLINKConnectionConfig *appConfig;

- (void)presentOverRoomViewController:(UIViewController*)viewController;

@end
