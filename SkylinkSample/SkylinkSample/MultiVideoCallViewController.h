//
//  MultiVideoCallViewController.h
//  Skylink_Examples
//
//  Created by Romain Pellen on 11/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>

@interface MultiVideoCallViewController : UIViewController <SKYLINKConnectionRecordingDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate>

@property (strong, nonatomic) NSString *skylinkApiKey;
@property (strong, nonatomic) NSString *skylinkApiSecret;

@end
