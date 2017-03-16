//
//  VideCallViewController.h
//  Skylink_Examples
//
//  Created by Romain Pellen on 11/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>

@interface VideoCallViewController : UIViewController <SKYLINKConnectionStatsDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate>

@property (strong, nonatomic) NSString *skylinkApiKey;
@property (strong, nonatomic) NSString *skylinkApiSecret;

@end
