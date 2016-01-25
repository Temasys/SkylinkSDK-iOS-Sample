//
//  TEMRoomViewController.h
//  TEM
//
//  Created by macbookpro on 01/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <SKYLINK/SKYLINK.h>
#import <UIKit/UIKit.h>

#import "TEMRichVideoView.h"

@interface TEMRoomViewController : UIViewController <SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionFileTransferDelegate, UIAlertViewDelegate, TEMVideoViewDelegate>

- (id)initWithRoomName:(NSString*)roomName displayName:(NSString*)displayName;

- (void)sendChatMessage:(NSString *)message target:(NSString*)target;
- (void)startFileTransfer:(NSString*)userId url:(NSURL*)fileURL type:(SKYLINKAssetType)transferType;

@end
