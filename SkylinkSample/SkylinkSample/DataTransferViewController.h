//
//  DataTransferViewController.h
//  SkylinkSample
//
//  Created by Romain Pellen on 08/06/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>

@interface DataTransferViewController : UIViewController <SKYLINKConnectionMessagesDelegate, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate>


@property (strong, nonatomic) NSString *skylinkApiKey;
@property (strong, nonatomic) NSString *skylinkApiSecret;


@end
