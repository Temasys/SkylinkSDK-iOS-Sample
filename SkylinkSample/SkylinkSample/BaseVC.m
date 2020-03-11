//
//  BaseVC.m
//  SkylinkSample
//
//  Created by Charlie on 26/11/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import "BaseVC.h"
#import "AudioCallViewController.h"
#import "VideoCallViewController.h"
#import "MessagesViewController.h"
#import "MultiVideoCallViewController.h"
#import "FileTransferViewController.h"
#import "DataTransferViewController.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self setupRoomName];
}

- (void)initUI{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backToMainMenu)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
}
- (void)setupRoomName{
    if ([ROOM_NAME isNotEmpty]) {
        roomName = ROOM_NAME;
        return;
    }
    if ([self isKindOfClass:[AudioCallViewController class]]) {
        roomName = ROOM_AUDIO; return;
    }
    if ([self isKindOfClass:[VideoCallViewController class]]) {
        roomName = ROOM_ONE_TO_ONE_VIDEO; return;
    }
    if ([self isKindOfClass:[MessagesViewController class]]) {
        roomName = ROOM_MESSAGES; return;
    }
    if ([self isKindOfClass:[MultiVideoCallViewController class]]) {
        roomName = ROOM_MULTI_VIDEO; return;
    }
    if ([self isKindOfClass:[FileTransferViewController class]]) {
        roomName = ROOM_FILE_TRANSFER; return;
    }
    if ([self isKindOfClass:[DataTransferViewController class]]) {
        roomName = ROOM_DATA_TRANSFER; return;
    }
}
- (void)showInfo {
    showAlertTouchDismiss([NSString stringWithFormat:@"%@", NSStringFromClass([self class])], [NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", roomName, _skylinkConnection.localPeerId, [APP_KEY substringFromIndex: [APP_KEY length] - 7], [SKYLINKConnection getSkylinkVersion]]);
//    showAlert([NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])], [NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", roomName, _skylinkConnection.localPeerId, [APP_KEY substringFromIndex: [APP_KEY length] - 7], [SKYLINKConnection getSkylinkVersion]]);
}
- (void)backToMainMenu{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_skylinkConnection unlockTheRoom:nil];
    [_skylinkConnection disconnect:^(NSError * _Nullable error) {
        if (!error) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}
- (void)startLocalMediaDevice:(SKYLINKMediaDevice)mediaDevice{
    [_skylinkConnection createLocalMediaWithMediaDevice:mediaDevice mediaMetadata:@"" callback:^(NSError * _Nullable error) {
        if (error) {
            showAlertAutoDismiss(@"Error", error.localizedDescription, 2.0, self);
        }
    }];
}
- (void)joinRoom{
    [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:roomName userData:USER_NAME callback:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
}
@end
