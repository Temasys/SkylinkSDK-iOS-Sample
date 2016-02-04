//
//  MultiVideoCallViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 11/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "MultiVideoCallViewController.h"
#import <AVFoundation/AVFoundation.h>


#define ROOM_NAME  @"MULTI-VIDEO-CALL-ROOM"


@interface MultiVideoCallViewController ()
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

// Other properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSMutableArray *peerIds;

@property (strong, nonatomic) NSMutableDictionary *peersInfos;

@end



@implementation MultiVideoCallViewController {
    BOOL isRoomLocked;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.peerIds = [[NSMutableArray alloc] init];
        isRoomLocked = NO;
        self.peersInfos = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"SKYLINKConnection version = %@", [SKYLINKConnection getSkylinkVersion]);
    
    self.title = @"Multi Party Video Call";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = YES;
    config.audio = YES;
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.mediaDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
    [SKYLINKConnection setVerbose:TRUE];
    [self.skylinkConnection connectToRoomWithSecret:self.skylinkApiSecret roomName:ROOM_NAME userInfo:nil];
}

-(void)disconnect {
    [self.activityIndicator startAnimating];
    if (self.skylinkConnection) [self.skylinkConnection disconnect:^{
        [self.activityIndicator stopAnimating];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

-(void)showInfo {
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])] message:[NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_NAME, self.skylinkConnection.myPeerId, [self.skylinkApiKey substringFromIndex: [self.skylinkApiKey length] - 7],  [SKYLINKConnection getSkylinkVersion]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self updatePeersVideosFrames];
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate
- (void)connection:(SKYLINKConnection *)connection didLockTheRoom:(BOOL)lockStatus peerId:(NSString *)peerId {
    isRoomLocked = lockStatus;
    [self.lockButton setImage:[UIImage imageNamed:( (isRoomLocked) ? @"LockFilled" : @"Unlock.png")] forState:UIControlStateNormal];
}

- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Inside %s", __FUNCTION__);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.localVideoContainerView.alpha = 1;
        });
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
    
    if (![self.peerIds containsObject:peerId]) [self.peerIds addObject:peerId];
    if (self.peerIds.count >= 4) [self lockRoom:YES];
    if (![self.peersInfos.allKeys containsObject:peerId]) [self.peersInfos addEntriesFromDictionary:@{peerId : @{@"videoView" : [NSNull null], @"videoSize" : [NSNull null], @"isAudioMuted" : [NSNull null], @"isVideoMuted" : [NSNull null]} }];
    
    [self.peersInfos setObject:@{@"videoView" : self.peersInfos[peerId][@"videoView"],
                                 @"videoSize" : [NSValue valueWithCGSize:CGSizeMake(pmProperties.videoWidth, pmProperties.videoHeight)],
                                 @"isAudioMuted" : [NSNumber numberWithBool:pmProperties.isAudioMuted],
                                 @"isVideoMuted" : [NSNumber numberWithBool:pmProperties.isVideoMuted] }
                        forKey:peerId];
    
    [self refreshPeerViews];
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ left the room with message: %@", peerId, errorMessage);
    [self.peerIds removeObject:peerId];
    [self.peersInfos removeObjectForKey:peerId];
    [self lockRoom:NO];
    
    [self refreshPeerViews];
}

- (void)connection:(SKYLINKConnection*)connection didRenderPeerVideo:(UIView*)peerVideoView peerId:(NSString*)peerId {
    if (![self.peerIds containsObject:peerId]) [self.peerIds addObject:peerId];
    if (![self.peersInfos.allKeys containsObject:peerId]) [self.peersInfos addEntriesFromDictionary:@{peerId : @{@"videoView" : [NSNull null], @"videoSize" : [NSNull null], @"isAudioMuted" : [NSNull null], @"isVideoMuted" : [NSNull null] } }];
    self.peersInfos[peerId] = @{@"videoView" : peerVideoView, @"videoSize" : self.peersInfos[peerId][@"videoSize"], @"isAudioMuted" : self.peersInfos[peerId][@"isAudioMuted"], @"isVideoMuted" : self.peersInfos[peerId][@"isVideoMuted"] };
    
    [self refreshPeerViews];
}

#pragma mark - SKYLINKConnectionMediaDelegate
- (void)connection:(SKYLINKConnection*)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView*)videoView
{
    if (videoSize.height > 0 && videoSize.width > 0) {
        UIView *correspondingContainerView = [self containerViewForVideoView:videoView];
        
        if (correspondingContainerView && ![correspondingContainerView isEqual:self.localVideoContainerView]) {
            NSInteger i = [self indexForContainerView:correspondingContainerView];
            if (i != NSNotFound) {
                
                self.peersInfos[self.peerIds[i]] = @{@"videoView" : self.peersInfos[self.peerIds[i]][@"videoView"], @"videoSize" : [NSValue valueWithCGSize:videoSize], @"isAudioMuted" : self.peersInfos[self.peerIds[i]][@"isAudioMuted"], @"isVideoMuted" : self.peersInfos[self.peerIds[i]][@"isVideoMuted"] };
            }
        }
        
        videoView.frame = (self.videoAspectSegmentControl.selectedSegmentIndex == 0 || [correspondingContainerView isEqual:self.localVideoContainerView]) ? [self aspectFillRectForSize:videoSize containedInRect:correspondingContainerView.frame] : AVMakeRectWithAspectRatioInsideRect(videoSize, correspondingContainerView.bounds);
    }
}

- (void)connection:(SKYLINKConnection *)connection didToggleAudio:(BOOL)isMuted peerId:(NSString *)peerId {
    if ([self.peersInfos.allKeys containsObject:peerId]) self.peersInfos[peerId] = @{@"videoView" : self.peersInfos[peerId][@"videoView"], @"videoSize" : self.peersInfos[peerId][@"videoSize"], @"isAudioMuted" : [NSNumber numberWithBool:isMuted], @"isVideoMuted" : self.peersInfos[peerId][@"isVideoMuted"] };
    [self refreshPeerViews];
}

- (void)connection:(SKYLINKConnection *)connection didToggleVideo:(BOOL)isMuted peerId:(NSString *)peerId {
    if ([self.peersInfos.allKeys containsObject:peerId]) self.peersInfos[peerId] = @{@"videoView" : self.peersInfos[peerId][@"videoView"], @"videoSize" : self.peersInfos[peerId][@"videoSize"], @"isAudioMuted" : self.peersInfos[peerId][@"isAudioMuted"], @"isVideoMuted" : [NSNumber numberWithBool:isMuted] };
    [self refreshPeerViews];
}

#pragma mark - Utils

-(void)addRenderedVideo:(UIView *)videoView insideContainer:(UIView *)containerView mirror:(BOOL)shouldMirror {
    videoView.frame = containerView.bounds;
    if (shouldMirror) videoView.transform = CGAffineTransformMakeScale(-1.0, 1.0); // to see ourself like in a mirror
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


-(UIView *)containerViewForVideoView:(UIView *)videoView {
    UIView *correspondingContainerView;
    if ([videoView isDescendantOfView:self.localVideoContainerView]) {
        correspondingContainerView = self.localVideoContainerView;
    }
    else if ([videoView isDescendantOfView:self.firstPeerVideoContainerView]) {
        correspondingContainerView = self.firstPeerVideoContainerView;
    }
    else if ([videoView isDescendantOfView:self.secondPeerVideoContainerView]) {
        correspondingContainerView = self.secondPeerVideoContainerView;
    }
    else if ([videoView isDescendantOfView:self.thirdPeerVideoContainerView]) {
        correspondingContainerView = self.thirdPeerVideoContainerView;
    }
    return correspondingContainerView;
}

-(NSInteger)indexForContainerView:(UIView *)v {
    return [@[self.firstPeerVideoContainerView, self.secondPeerVideoContainerView, self.thirdPeerVideoContainerView] indexOfObject:v];
}

-(void)refreshPeerViews {
    NSArray *peerContainerViews =  @[self.firstPeerVideoContainerView, self.secondPeerVideoContainerView, self.thirdPeerVideoContainerView];
    // clean the container views
    for (UIView *viewToClean in peerContainerViews) {
        for (UIView *aSubview in viewToClean.subviews) {
            [aSubview removeFromSuperview];
        }
    }
    NSArray *peerLabels = @[self.firstPeerLabel, self.secondPeerLabel, self.thirdPeerLabel];
    for (NSString *aPeerId in self.peerIds) {
        // Add the rendered view
        NSInteger index = [self.peerIds indexOfObject:aPeerId];
        if (index < peerContainerViews.count) [self addRenderedVideo:self.peersInfos[aPeerId][@"videoView"] insideContainer:peerContainerViews[index] mirror:NO];
        // refresh the label
        id audioMuted = self.peersInfos[aPeerId][@"isAudioMuted"];
        id videoMuted = self.peersInfos[aPeerId][@"isVideoMuted"];
        NSString *mutedInfos = @"";
        if ([audioMuted isKindOfClass:[NSNumber class]] && [audioMuted boolValue]) mutedInfos = @"Audio muted";
        if ([videoMuted isKindOfClass:[NSNumber class]] && [videoMuted boolValue]) mutedInfos = (mutedInfos.length) ? [@"Video & " stringByAppendingString:mutedInfos] : @"Video muted";
        if (index < peerLabels.count) ((UILabel *)peerLabels[index]).text = mutedInfos;
        if (index < peerLabels.count) ((UILabel *)peerLabels[index]).hidden = !(mutedInfos.length);
    }
    for (NSUInteger i = self.peerIds.count; i < peerLabels.count; i++) {
        ((UILabel *)peerLabels[i]).hidden = YES;
    }
    // refresh the frames
    [self updatePeersVideosFrames];
}

-(void)updatePeersVideosFrames {
    
    for (int i = 0; i < self.peerIds.count && i < 3; i++) {
        id pvView = self.peersInfos[self.peerIds[i]][@"videoView"];
        id pvSize = self.peersInfos[self.peerIds[i]][@"videoSize"];
        if (pvView && [pvView isKindOfClass:[UIView class]] && pvSize && [pvSize isKindOfClass:[NSValue class]])
        {
            ((UIView *)pvView).frame = (self.videoAspectSegmentControl.selectedSegmentIndex == 0) ?
                [self aspectFillRectForSize:[((NSValue *)pvSize) CGSizeValue] containedInRect:[[self containerViewForVideoView:pvView] frame]]
                : AVMakeRectWithAspectRatioInsideRect([((NSValue *)pvSize) CGSizeValue], [[self containerViewForVideoView:pvView] bounds]);
        }
    }
}

-(void)lockRoom:(BOOL)shouldLock {
    (shouldLock) ? [self.skylinkConnection lockTheRoom] : [self.skylinkConnection unlockTheRoom];
    isRoomLocked = shouldLock;
    [self.lockButton setImage:[UIImage imageNamed:( (isRoomLocked) ? @"LockFilled" : @"Unlock.png")] forState:UIControlStateNormal];
}

#pragma mark - IBActions

- (IBAction)toogleVideoTap:(UIButton *)sender {
    [self.skylinkConnection muteVideo:!self.skylinkConnection.isVideoMuted];
    [sender setImage:[UIImage imageNamed:( (self.skylinkConnection.isVideoMuted) ? @"NoVideoFilled.png" : @"VideoCall.png")] forState:UIControlStateNormal];
    self.localVideoContainerView.hidden = (self.skylinkConnection.isVideoMuted);
}
- (IBAction)toogleSoundTap:(UIButton *)sender {
    [self.skylinkConnection muteAudio:!self.skylinkConnection.isAudioMuted];
    [sender setImage:[UIImage imageNamed:( (self.skylinkConnection.isAudioMuted) ? @"NoMicrophoneFilled.png" : @"Microphone.png")] forState:UIControlStateNormal];
}
- (IBAction)switchCameraTap:(UIButton *)sender {
    [self.skylinkConnection switchCamera];
}
- (IBAction)switchLockTap:(UIButton *)sender {
    [self lockRoom:!isRoomLocked];
}

- (IBAction)videoAspectSegmentControlChanged:(UISegmentedControl *)sender {
    [self updatePeersVideosFrames];
}

@end

