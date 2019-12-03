//
//  MultiVideoCallViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 11/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "MultiVideoCallViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Constant.h"
#import "Peer.h"
//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_MULTIVIDEOCALL"]
#define MY_PEER_ID @"myPeerId"

@interface MultiVideoCallViewController () <UIPickerViewDataSource, UIPickerViewDelegate, SKYLINKConnectionRecordingDelegate, SKYLINKConnectionMediaDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UIView *localVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *firstPeerVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *secondPeerVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *thirdPeerVideoContainerView;
@property (weak, nonatomic) IBOutlet UILabel *firstPeerLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondPeerLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdPeerLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *videoAspectSegmentControl;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIView *pickerViewContainer;
@property (weak, nonatomic) IBOutlet UIViewController *partipationsVC;
@property (weak, nonatomic) IBOutlet UIButton *restartButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleCameraButton;
// Other properties
//@property (strong, nonatomic) NSMutableArray *peerIds;
//@property (strong, nonatomic) NSMutableDictionary *peersInfos;
//@property (nonatomic, copy) NSString *cameraMediaID;
//@property (nonatomic, copy) NSString *audioMediaID;
//@property (nonatomic, strong) NSMutableArray<Peer *> *peerObjects;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *videoContainers;
@end

@implementation MultiVideoCallViewController {
    BOOL isRoomLocked;
    BOOL isRecording;
    BOOL isLocalCameraRunning;
    NSMutableArray<Peer *> *_peers;
}
#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    MyLog(@"SKYLINKConnection version = %@", [SKYLINKConnection getSkylinkVersion]);
    self.title = @"Multi Party Video Call";
    [self setupData];
}

- (void)setupData{
    //creating SKYLINKConnectionConfig
    _roomName = ROOM_MULTI_VIDEO;
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    [config setAudioVideoSendConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    config.isMultiTrackCreateEnable = YES;
    config.isMirrorLocalFrontCameraView = YES;
    //creating SKYLINKConnection
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.mediaDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;
    _skylinkConnection.enableLogs = YES;
    //init variables
    _peers = [NSMutableArray new];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startLocalMediaDevice:SKYLINKMediaDeviceCameraFront];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self joinRoom];
    });
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection{
    [_videoContainers.firstObject setAlpha:1.0];
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage{
    showAlert(@"Connection failed!", errorMessage);
}
- (void)connection:(SKYLINKConnection *)connection didDisconnectFromRoomWithSkylinkEvent:(NSDictionary *)skylinkEvent contextDescription:(NSString *)contextDescription{
    [self.activityIndicator stopAnimating];
}

#pragma mark - SKYLINKConnectionMediaDelegate
- (void)connection:(SKYLINKConnection *)connection didCreateLocalMedia:(SKYLINKMedia *)localMedia{
    NSLog(@"didCreateLocalMedia");
    //add media which is video only
    if (!localMedia) {
        return;
    }
    if (localMedia.skylinkMediaType != SKYLINKMediaTypeAudio) {
        [self addMedia:localMedia peerId:MY_PEER_ID];
        [self reloadVideoView];
    }
}
- (void)connection:(SKYLINKConnection *)connection didChangeLocalMedia:(SKYLINKMedia *)localMedia{
    NSLog(@"changed local media %d", localMedia.skylinkMediaState);
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didReceiveRemoteMedia:(SKYLINKMedia *)remoteMedia remotePeerId:(NSString *)remotePeerId{
    NSLog(@"didReceiveRemoteMedia: %u", remoteMedia.skylinkMediaType);
    if (!remoteMedia || !remotePeerId) {
        return;
    }
    //add media which is video only
    if (remoteMedia.skylinkMediaType != SKYLINKMediaTypeAudio) {
        [self addMedia:remoteMedia peerId:remotePeerId];
        [self reloadVideoView];
    }
}
- (void)connection:(SKYLINKConnection *)connection didChangeRemoteMedia:(SKYLINKMedia *)remoteMedia remotePeerId:(NSString *)remotePeerId{
    NSLog(@"didChangeRemoteMedia: %u", remoteMedia.skylinkMediaType);
}
- (void)connection:(SKYLINKConnection *)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView *)videoView peerId:(NSString *)peerId{
    NSLog(@"changed video size!");
    NSLog(@"peerId: %@", peerId);
    if (videoSize.height > 0 && videoSize.width > 0) {
        for (UIView* container in self.videoContainers) {
            if ([videoView isDescendantOfView:container]) {
                NSInteger _index = [self.videoContainers indexOfObject:container];
                if (_index==0) {
                    break;
                }
                _peers[_index].videoSize = videoSize;
                [videoView aspectFitRectForSize:videoSize container:container];
            }
        }
    }
}
#pragma mark - SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerInRoomWithRemotePeerId:(NSString *)remotePeerId userInfo:(id)userInfo{
    NSLog(@"didReceiveRemotePeerInRoomWithRemotePeerId: %@ \nuserInfo: %@", remotePeerId, userInfo);
    showAlertAutoDismiss(nil, [NSString stringWithFormat:@"%@ has joined room\n\nUserData:%@", remotePeerId, userInfo[@"userData"]], 2, self);
    if (remotePeerId){
        [self addMedia:nil peerId:remotePeerId];
        [self.pickerView reloadAllComponents];
    }
}
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel{
//    if (remotePeerId) {
//        showAlertAutoDismiss(nil, [NSString stringWithFormat:@"%@ has joined room\n\nUserData:%@", remotePeerId, userInfo[@"userData"]], 2, self);
//        [self addMedia:nil peerId:remotePeerId];
////        [_peers addObject:[[Peer alloc] initWithPeerID:remotePeerId]];
//        [self reloadVideoView];
//        [self.pickerView reloadAllComponents];
//    }
//    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didDisconnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel{
    if (remotePeerId) {
        [self removePeer:remotePeerId];
        [self reloadVideoView];
    }
    [self.activityIndicator stopAnimating];
}
- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerLeaveRoom:(NSString *)remotePeerId userInfo:(id)userInfo skylinkInfo:(NSDictionary *)skylinkInfo{
    
}
//- (void)connection:(SKYLINKConnection *)connection didChangeRemoteMedia:(SKYLINKMedia *)remoteMedia remotePeerId:(NSString *)remotePeerId{
//    if (remoteMedia.skylinkMediaType == SKYLINKMediaTypeVideoCamera) {
//        if (remoteMedia.skylinkMediaState == SKYLINKMediaStateUnavailable) {
//            <#statements#>
//        }
//    }
//}

#pragma mark - UIPickerView Delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _peers.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) return @"All";
    return [NSString stringWithFormat:@"%@:%@", _peers[row].userName, _peers[row].peerId];
}
#pragma mark - Private functions
- (void)removePeer:(NSString*)peerId{
    for (Peer *_peer in _peers) {
        if ([_peer.peerId isEqualToString:peerId]) {
            [_peers removeObject:_peer];
            return;
        }
    }
}
- (void)addMedia:(SKYLINKMedia *)media peerId:(NSString *)peerId{
    if (!peerId) {
        return;
    }
    Peer *_peer = nil;
    for (Peer *peer in _peers) {
        if ([peer.peerId isEqualToString:peerId]) {
            _peer = peer;
            break;
        }
    }
    if (!_peer) {
        _peer = [[Peer alloc] initWithPeerID:peerId];
        if ([peerId isEqualToString:MY_PEER_ID]) {
            [_peers insertObject:_peer atIndex:0];
        }else{
            [_peers addObject:_peer];
        }
    }
    if (media) {
        [_peer.medias addObject:media];
    }
//    NSLog(@"ccc===peers count: %lu", (unsigned long)_peers.count);
//    for (Peer *_peer in _peers) {
//        NSLog(@"peer: %@", _peer.peerId);
//        NSLog(@"medias count: %lu", (unsigned long)_peer.medias.count);
//        NSLog(@"first media: %d", _peer.medias.firstObject.skylinkMediaType);
//    }
}
- (void)reloadVideoView{
    //remove all videos
    for (UIView *view in _videoContainers) {
        [view removeSubviews];
    }
    //add videos from peers array
    NSLog(@"reload video. Peers count: %lu", (unsigned long)_peers.count);
    for (Peer *peer in _peers) {
        if ([peer.peerId isEqualToString:MY_PEER_ID] && peer.medias.firstObject) {
            [self addRenderedVideo:peer.medias.firstObject.skylinkVideoView insideContainer:_videoContainers.firstObject mirror:YES];
        }else{
            if (peer.medias.firstObject.skylinkMediaState!=SKYLINKMediaStateUnavailable) {
                NSInteger _index = MIN([_peers indexOfObject:peer], 3);
                NSLog(@"addview index: %ld", (long)_index);
                [self addRenderedVideo:peer.medias.firstObject.skylinkVideoView insideContainer:_videoContainers[_index] mirror:NO];
            }
        }
    }
}
- (void)addRenderedVideo:(UIView *)videoView insideContainer:(UIView *)containerView mirror:(BOOL)shouldMirror {
    [videoView aspectFitRectForSize:videoView.frame.size container:containerView];
//    [containerView addSubview:videoView];
    [containerView insertSubview:videoView atIndex:0];
}
- (void)startRecording {
    if (!_skylinkConnection.isRecording) {
        [_skylinkConnection startRecording:^(NSError * _Nullable error) {
            if (error) MyLog(@"%@", error.localizedDescription);
            showAlertAutoDismiss(nil, @"You recording is started", 3, self);
        }];
    }
}

- (void)stopRecording {
    if (_skylinkConnection.isRecording) {
        [_skylinkConnection stopRecording:^(NSError * _Nullable error) {
            if (error) MyLog(@"%@", error.localizedDescription);
            showAlertAutoDismiss(nil, @"You recording is stopped", 3, self);
        }];
    }
}

#pragma mark - IBActions
- (IBAction)toogleVideoTap:(UIButton *)sender {
    [_skylinkConnection muteVideo:!_skylinkConnection.isVideoMuted];
    [sender setImage:[UIImage imageNamed:( (_skylinkConnection.isVideoMuted) ? @"NoVideoFilled.png" : @"VideoCall.png")] forState:UIControlStateNormal];
}
- (IBAction)toogleSoundTap:(UIButton *)sender {
    [_skylinkConnection muteAudio:!_skylinkConnection.isAudioMuted];
    [sender setImage:[UIImage imageNamed:( (_skylinkConnection.isAudioMuted) ? @"NoMicrophoneFilled.png" : @"Microphone.png")] forState:UIControlStateNormal];
}
- (IBAction)switchCameraTap:(UIButton *)sender {
    [_skylinkConnection switchCamera:nil];
}
- (IBAction)lockRoom:(UIButton *)sender {
    isRoomLocked ? [_skylinkConnection unlockTheRoom:nil] : [_skylinkConnection lockTheRoom:nil];
    isRoomLocked = !isRoomLocked;
    [self.lockButton setImage:[UIImage imageNamed:isRoomLocked ? @"LockFilled" : @"Unlock.png"] forState:UIControlStateNormal];
}

- (IBAction)videoAspectSegmentControlChanged:(UISegmentedControl *)sender {
//    [self updatePeersVideosFrames];
}

- (IBAction)recording:(UISwitch *)sender {
    sender.isOn ? [self startRecording] : [self stopRecording];
}

- (IBAction)restart {
    [self.pickerViewContainer setHidden:NO];
}

- (IBAction)toolbarDone {
    [self.pickerViewContainer setHidden:YES];
}

- (IBAction)toolbarSend {
    [self.pickerViewContainer setHidden:YES];
    if ([self.pickerView selectedRowInComponent:0] == 0) {
        [_skylinkConnection refreshConnectionWithRemotePeerId:nil doIceRestart:YES callback:nil];
    }else{
        NSString *_selectedPeerId = _peers[[_pickerView selectedRowInComponent:0]].peerId;
        [_skylinkConnection refreshConnectionWithRemotePeerId:_selectedPeerId doIceRestart:YES callback:nil];
    }
}
@end

