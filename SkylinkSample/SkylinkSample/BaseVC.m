//
//  BaseVC.m
//  SkylinkSample
//
//  Created by Charlie on 26/11/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import "BaseVC.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)initUI{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backToMainMenu)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
}

- (void)showInfo {
    showAlertAutoDismiss([NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])], [NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_ONE_TO_ONE_VIDEO, _skylinkConnection.localPeerId, [APP_KEY substringFromIndex: [APP_KEY length] - 7], [SKYLINKConnection getSkylinkVersion]], 3, self);
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
    [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:_roomName userData:USER_NAME callback:nil];
}
@end
