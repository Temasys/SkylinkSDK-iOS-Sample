//
//  BaseVC.h
//  SkylinkSample
//
//  Created by Charlie on 26/11/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseVC : UIViewController<SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate>{
    SKYLINKConnection *_skylinkConnection;
    NSString *_roomName;
}
- (void)startLocalMediaDevice:(SKYLINKMediaDevice)mediaDevice;
- (void)joinRoom;
@end

NS_ASSUME_NONNULL_END
