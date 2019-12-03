//
//  VideCallViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 11/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "VideoCallViewController.h"
#import <AVFoundation/AVFoundation.h>

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_ONETOONEVIDEOCALL"]

@interface VideoCallViewController ()<SKYLINKConnectionMediaDelegate>

// IBOutlets
@property (weak, nonatomic) IBOutlet UIView *localVideoContainerView; // note: .clipsToBounds property set to YES via storyboard;
@property (weak, nonatomic) IBOutlet UIView *localVideoContainerView2;
@property (weak, nonatomic) IBOutlet UIView *remotePeerVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *remotePeerVideoContainerView2;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *videoViews;

@end

@implementation VideoCallViewController
{
    BOOL _isJoinRoom;
    NSMutableArray *_localMedias;
    NSMutableArray *_remoteMedias;
    NSString *_remotePeerId;
}
#pragma mark - INIT
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"1-1 Video Call";
    [self initData];
}
- (void)initData{
    _isJoinRoom = NO;
    _localMedias = [NSMutableArray new];
    _remoteMedias = [NSMutableArray new];
    APP_KEY = APP_KEY;
    APP_SECRET = APP_SECRET;
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    [config setAudioVideoSendConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    config.isMultiTrackCreateEnable = YES;
    config.roomSize = SKYLINKRoomSizeSmall;
    config.isMirrorLocalFrontCameraView = true;
    
    // Creating SKYLINKConnection
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.mediaDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;
    _skylinkConnection.enableLogs = YES;
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection{
//    skylinkLog("Inside \(#function)");
    self.title = _roomName;
    [self.callButton setBackgroundImage:[UIImage imageNamed:@"call_off"] forState:UIControlStateNormal];
//    __weak __typeof(self)weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        __strong __typeof(weakSelf)strongSelf = weakSelf;
//
//    });
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage{
    showAlert(@"Connection failed!", errorMessage);
}
- (void)connection:(SKYLINKConnection *)connection didDisconnectFromRoomWithSkylinkEvent:(NSDictionary *)skylinkEvent contextDescription:(NSString *)contextDescription{
    [self.callButton setBackgroundImage:[UIImage imageNamed:@"call_on"] forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];
}
#pragma mark - SKYLINKConnectionMediaDelegate
- (void)connection:(SKYLINKConnection *)connection didCreateLocalMedia:(SKYLINKMedia *)localMedia{
    if (!localMedia) {
        return;
    }
    [_localMedias addObject:localMedia];
    [self reloadVideoView];
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didChangeLocalMedia:(SKYLINKMedia *)localMedia{
    NSLog(@"changed local media %d", localMedia.skylinkMediaState);
    [self.activityIndicator stopAnimating];
}

- (void)connection:(SKYLINKConnection *)connection didChangeRemoteMedia:(SKYLINKMedia *)remoteMedia remotePeerId:(NSString *)remotePeerId{
    NSInteger _index = -1;
    for (SKYLINKMedia *media in _remoteMedias) {
        if (media.skylinkMediaID == remotePeerId) {
            _index = [_remoteMedias indexOfObject:media];
        }
    }
    if (_index>=0) {
        [_remoteMedias replaceObjectAtIndex:_index withObject:remoteMedia];
        [self reloadVideoView];
    }
}
- (void)connection:(SKYLINKConnection *)connection didReceiveRemoteMedia:(SKYLINKMedia *)remoteMedia remotePeerId:(NSString *)remotePeerId{
    if (!remoteMedia || !remotePeerId) {
        return;
    }
    [_remoteMedias addObject:remoteMedia];
    [self reloadVideoView];
}
- (void)connection:(SKYLINKConnection *)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView *)videoView peerId:(NSString *)peerId{
    if (videoSize.height > 0 && videoSize.width > 0) {
        for (UIView* container in @[self.localVideoContainerView, self.localVideoContainerView2, self.remotePeerVideoContainerView, self.remotePeerVideoContainerView2]) {
            if ([videoView isDescendantOfView:container]) {
                [videoView aspectFitRectForSize:videoSize container:container];
            }
        }
    }
}
- (void)connection:(SKYLINKConnection *)connection didDestroyLocalMedia:(SKYLINKMedia *)localMedia{
//    NSInteger _index = -1;
    for (SKYLINKMedia *media in _localMedias ) {
        if ([media isEqual:localMedia]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_localMedias removeObject:media];
                [self reloadVideoView];
                return;
            });
        }
    }
//    if (_index>=0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self->_localMedias removeObjectAtIndex:_index];
//            [self reloadVideoView];
//        });
//    }
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel{
    showAlertAutoDismiss(nil, [NSString stringWithFormat:@"%@ has joined room\nUserData:%@", remotePeerId, userInfo[@"userData"]], 2, self);
    _remotePeerId = remotePeerId;
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didDisconnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel{
    [_remoteMedias removeAllObjects];
    [self reloadVideoView];
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerLeaveRoom:(NSString *)remotePeerId userInfo:(id)userInfo skylinkInfo:(NSDictionary *)skylinkInfo{
    
}

#pragma mark - Private functions
- (void)addRenderedVideo:(UIView *)videoView insideContainer:(UIView *)containerView mirror:(BOOL)shouldMirror {
    [videoView aspectFitRectForSize:videoView.frame.size container:containerView];
    [containerView removeSubviews];
    [containerView insertSubview:videoView atIndex:0];
}
- (void)changeLocalMediaStateWithMediaId:(NSString*)mediaId state:(SKYLINKMediaState)state{
    [self.activityIndicator startAnimating];
    [_skylinkConnection changeLocalMediaStateWithMediaId:mediaId mediaState:state callback:^(NSError * _Nullable error) {
        if (error) {
            [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
        }
        [self.activityIndicator stopAnimating];
    }];
}

- (void)destroyLocalMedia{
    while (_localMedias.count>0) {
        SKYLINKMedia *media = _localMedias.firstObject;
        [_skylinkConnection destroyLocalMediaWithMediaId:media.skylinkMediaID callback:nil];
    }
}
- (void)reloadVideoView{
    for (UIView *container in _videoViews) {
        [container removeSubviews];
    }
    for (SKYLINKMedia *localMedia in _localMedias) {
        if (localMedia.skylinkMediaType == SKYLINKMediaTypeVideoCamera) {
            [self addRenderedVideo:localMedia.skylinkVideoView insideContainer:self.localVideoContainerView mirror:true];
        }else if(localMedia.skylinkMediaType == SKYLINKMediaTypeVideoScreen){
            [self addRenderedVideo:localMedia.skylinkVideoView insideContainer:self.localVideoContainerView2 mirror:true];
        }
    }
    for (SKYLINKMedia *remoteMedia in _remoteMedias) {
        if (remoteMedia.skylinkMediaType == SKYLINKMediaTypeVideoCamera) {
            [self addRenderedVideo:remoteMedia.skylinkVideoView insideContainer:self.remotePeerVideoContainerView mirror:false];
        }else if(remoteMedia.skylinkMediaType == SKYLINKMediaTypeVideoScreen){
            [self addRenderedVideo:remoteMedia.skylinkVideoView insideContainer:self.remotePeerVideoContainerView2 mirror:false];
        }
    }
}


#pragma mark - IBActions
- (IBAction)joinRoom{
    [self.activityIndicator startAnimating];
    if (_isJoinRoom) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [_skylinkConnection unlockTheRoom:nil];
        [_skylinkConnection disconnect:^(NSError * _Nullable error) {
            if (error) {
                [self.remotePeerVideoContainerView removeSubviews];
                [self.remotePeerVideoContainerView2 removeSubviews];
                //                    self.localVideoContainerView.removeSubviews()
                [self destroyLocalMedia];
                [self.callButton setBackgroundImage:[UIImage imageNamed:@"call_on"] forState:UIControlStateNormal];
                [self.activityIndicator stopAnimating];
            }
        }];
    }else{
        [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:ROOM_ONE_TO_ONE_VIDEO userData:USER_NAME callback:nil];
    }
    _isJoinRoom = !_isJoinRoom;
}
    
- (IBAction)startCamera{
    [self startLocalMediaDevice:SKYLINKMediaDeviceCameraFront];
}
    
- (IBAction)startAudio{
    [self startLocalMediaDevice:SKYLINKMediaDeviceMicrophone];
}
    
- (IBAction)startScreen{
    [self startLocalMediaDevice:SKYLINKMediaDeviceScreen];
}
    
- (IBAction)videoStateChanged:(UISegmentedControl*)sender{
    if (!_isJoinRoom) {
        sender.selectedSegmentIndex = 0;
        return;
    }
    for(SKYLINKMedia *media in _localMedias){
        if (media.skylinkMediaType == SKYLINKMediaTypeVideoCamera){
            [self changeLocalMediaStateWithMediaId:media.skylinkMediaID state:(int)sender.selectedSegmentIndex+1];
        }
    }
}
    
- (IBAction)audioStateChanged:(UISegmentedControl*)sender{
    if (!_isJoinRoom){
        sender.selectedSegmentIndex = 0;
        return;
    }
    for(SKYLINKMedia *media in _localMedias){
        if (media.skylinkMediaType == SKYLINKMediaTypeAudio){
            [self changeLocalMediaStateWithMediaId:media.skylinkMediaID state:(int)sender.selectedSegmentIndex+1];
        }
    }
}
    
- (IBAction)screenStateChanged:(UISegmentedControl*)sender{
    if (!_isJoinRoom){
        sender.selectedSegmentIndex = 0;
        return;
    }
    for(SKYLINKMedia *media in _localMedias){
        if (media.skylinkMediaType == SKYLINKMediaTypeVideoScreen){
            [self changeLocalMediaStateWithMediaId:media.skylinkMediaID state:(int)sender.selectedSegmentIndex+1];
        }
    }
}
- (IBAction)removeTrack:(UIButton*)sender{
    for (SKYLINKMedia *media in _localMedias) {
        if (media.skylinkMediaType == sender.tag) {
            [_skylinkConnection destroyLocalMediaWithMediaId:media.skylinkMediaID callback:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"failed to remove track %@", error);
                }
            }];
        }
    }
}
@end

