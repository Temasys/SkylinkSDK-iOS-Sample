//
//  VideCallViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 11/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "VideoCallViewController.h"
#import <AVFoundation/AVFoundation.h>


#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_ONETOONEVIDEOCALL"]

@interface VideoCallViewController ()

// IBOutlets
@property (weak, nonatomic) IBOutlet UIView *localVideoContainerView; // note: .clipsToBounds property set to YES via storyboard;
@property (weak, nonatomic) IBOutlet UIView *remotePeerVideoContainerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// references
@property (strong, nonatomic) UIView *peerVideoView;
@property (assign, nonatomic) CGSize peerVideoSize;

// Other properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSString *remotePeerId;

@end


@implementation VideoCallViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSLog(@"SKYLINKConnection version = %@", [SKYLINKConnection getSkylinkVersion]);
    self.title = @"1-1 Video Call";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.receiveVideo = YES;
    config.sendVideo = YES;
    config.audio = YES;
    //config.maxVideoBitrate = 256; // default is 512
    //config.maxAudioBitrate = 20; // default is no limit same for data
    // uncomment this to have a low but more effective video resolution: [config advancedSettingKey:@"preferedCaptureSessionPresets" setValue:@[AVCaptureSessionPresetLow]];
    
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.mediaDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
#ifdef DEBUG
    [SKYLINKConnection setVerbose:TRUE];
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.skylinkConnection connectToRoomWithSecret:self.skylinkApiSecret roomName:ROOM_NAME userInfo:nil];
        self.skylinkConnection.statsDelegate = self;
        [self continuousStats];
    });
}

-(void)disconnect {
    [self.activityIndicator startAnimating];
    [self.skylinkConnection unlockTheRoom];
    if (self.skylinkConnection) [self.skylinkConnection disconnect:^{
        [self.activityIndicator stopAnimating];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

-(void)showInfo {
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])] message:[NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_NAME, self.skylinkConnection.myPeerId, [self.skylinkApiKey substringFromIndex: [self.skylinkApiKey length] - 7], [SKYLINKConnection getSkylinkVersion]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    if (self.peerVideoView) {
        self.peerVideoView.frame = [self aspectFillRectForSize:self.peerVideoSize containedInRect:self.remotePeerVideoContainerView.frame];
    }
}

-(void)continuousStats {
    if (self.skylinkConnection) {
        [self.skylinkConnection getWebRTCStatsForPeerId:nil mediaDirection:0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.skylinkConnection) [self continuousStats];
        });
    }
}
-(void)connection:(SKYLINKConnection *)connection didGetWebRTCStats:(NSDictionary *)stats forPeerId:(NSString *)peerId mediaDirection:(int)mediaDirection {
    NSLog(@"%@", [NSString stringWithFormat:@"#Stats\nmd=%d pid=%@\n%@", mediaDirection, peerId, [stats description]]);
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate

- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Inside %s with success", __FUNCTION__);
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connection failed" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
}

- (void)connection:(SKYLINKConnection*)connection didRenderUserVideo:(UIView*)userVideoView {
    [self addRenderedVideo:userVideoView insideContainer:self.localVideoContainerView mirror:YES];
}

- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self.activityIndicator stopAnimating];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate

- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId {
    [self.activityIndicator stopAnimating];
    self.remotePeerId = peerId;
}

- (void)connection:(SKYLINKConnection*)connection didRenderPeerVideo:(UIView*)peerVideoView peerId:(NSString*)peerId {
    [self addRenderedVideo:peerVideoView insideContainer:self.remotePeerVideoContainerView mirror:NO];
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    self.remotePeerId = nil;
    [self.skylinkConnection unlockTheRoom];
}


#pragma mark - SKYLINKConnectionMediaDelegate
- (void)connection:(SKYLINKConnection*)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView*)videoView
{
    if (videoSize.height > 0 && videoSize.width > 0) {
        UIView *correspondingContainerView;
        if ([videoView isDescendantOfView:self.localVideoContainerView]) {
            correspondingContainerView = self.localVideoContainerView;
        }
        else {
            correspondingContainerView = self.remotePeerVideoContainerView;
            self.peerVideoView = videoView;
            self.peerVideoSize = videoSize;
        }
        videoView.frame = [self aspectFillRectForSize:videoSize containedInRect:correspondingContainerView.frame];
        // for aspect fit, use AVMakeRectWithAspectRatioInsideRect(videoSize, correspondingContainerView.bounds);
    }
}

#pragma mark - Utils

// for didRender.. Delegates
-(void)addRenderedVideo:(UIView *)videoView insideContainer:(UIView *)containerView mirror:(BOOL)shouldMirror {
    videoView.frame = containerView.bounds;
    for (UIView *subview in containerView.subviews) {
        [subview removeFromSuperview];
    }
    [containerView insertSubview:videoView atIndex:0];
}

-(CGRect)aspectFillRectForSize:(CGSize)insideSize containedInRect:(CGRect)containerRect {
    CGFloat maxFloat = MAX(containerRect.size.height, containerRect.size.width);
    CGFloat aspectRatio = insideSize.width / insideSize.height;
    CGRect frame = CGRectMake(0, 0, containerRect.size.width, containerRect.size.height);
    if (insideSize.width < insideSize.height) {
        frame.size.width = maxFloat;
        frame.size.height = frame.size.width / aspectRatio;
    } else {
        frame.size.height = maxFloat;
        frame.size.width = frame.size.height * aspectRatio;
    }
    frame.origin.x = (containerRect.size.width - frame.size.width) / 2;
    frame.origin.y = (containerRect.size.height - frame.size.height) / 2;
    return frame;
}

#pragma mark - IBActions

- (IBAction)toogleVideoTap:(UIButton *)sender{
    [self.skylinkConnection muteVideo:!self.skylinkConnection.isVideoMuted];
    [sender setImage:[UIImage imageNamed:( (self.skylinkConnection.isVideoMuted) ? @"NoVideoFilled.png" : @"VideoCall.png")] forState:UIControlStateNormal];
    //self.localVideoContainerView.hidden = (self.skylinkConnection.isVideoMuted);
}
- (IBAction)toogleSoundTap:(UIButton *)sender {
    [self.skylinkConnection muteAudio:!self.skylinkConnection.isAudioMuted];
    [sender setImage:[UIImage imageNamed:( (self.skylinkConnection.isAudioMuted) ? @"NoMicrophoneFilled.png" : @"Microphone.png")] forState:UIControlStateNormal];
}
- (IBAction)switchCameraTap:(UIButton *)sender {
    [self.skylinkConnection switchCamera];
}

- (IBAction)refreshTap:(UIButton *)sender {
    
    if (self.remotePeerId) {
        [self.activityIndicator startAnimating];
        [self.skylinkConnection unlockTheRoom];
        [self.skylinkConnection refreshConnection:self.remotePeerId];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"No peer connection to refresh" message:@"Tap this button to refresh the peer connection if needed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end

