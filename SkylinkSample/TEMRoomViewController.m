//
//  TEMRoomViewController.m
//  TEM
//
//  Created by macbookpro on 01/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "TEMRoomViewController.h"

#import "TEMAppDelegate.h"
#import "TEMCommon.h"
#import "TEMPresenceNavigationController.h"
#import "TEMPresenceTableViewController.h"

typedef enum : NSUInteger {
    RoomAlertViewTypeConnectionClosed,
    RoomAlertViewTypeFileRequest,
    RoomAlertViewTypeFileCancel
} RoomAlertViewType;

@interface TEMControlButton : UIButton

@property(nonatomic, unsafe_unretained) NSInteger myState;

@end

@implementation TEMControlButton

@end

@interface TEMFileAlertView : UIAlertView

@property (nonatomic, copy) NSString *remotePeerId;
@property (nonatomic, copy) NSString *fileName;

@end

@implementation TEMFileAlertView

@end

@interface TEMRoomViewController () {
    NSMutableArray *remotePeerArray;
    NSMutableArray *remoteVideoViewArray;
    
    NSTimer *timer;
    
    SKYLINKConnection *mySkylink;
    TEMPresenceNavigationController *presenceNavigationController;
}

@property (weak, nonatomic) IBOutlet MPVolumeView *volumeView;

@property (weak, nonatomic) IBOutlet TEMControlButton *audioButton;
@property (weak, nonatomic) IBOutlet TEMControlButton *lockButton;
@property (weak, nonatomic) IBOutlet TEMControlButton *videoButton;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *configLabel;
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;

@property (strong, nonatomic) IBOutlet UIView *controlView;

@property (weak, nonatomic) TEMRichVideoView *localVideoView;
@property (weak, nonatomic) TEMRichVideoView *remoteVideoView;

@property (unsafe_unretained, nonatomic) NSInteger timerCount;

@property (copy, nonatomic) NSString *myDisplayName;
@property (copy, nonatomic) NSString *roomName;

@property (unsafe_unretained, nonatomic) UIInterfaceOrientation statusBarOrientation;
@property (weak, nonatomic) TEMPresenceTableViewController *presenceTableViewController;

@end

@implementation TEMRoomViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithRoomName:(NSString*)roomName displayName:(NSString*)displayName
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.myDisplayName = displayName;
        self.roomName = roomName;
        self.timerCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.timeLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.toastLabel.layer.cornerRadius = self.toastLabel.bounds.size.height/4;
    
    self.statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // Create configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = YES;
    config.audio = YES;
    config.fileTransfer = YES;
    config.dataChannel = YES;
    config.timeout = 30;
    ((TEMAppDelegate*)[UIApplication sharedApplication].delegate).appConfig = config;
    
    // Instante SKYLINKConnection
    [SKYLINKConnection setVerbose:TRUE];
    mySkylink = [[SKYLINKConnection alloc] initWithConfig:config appKey:];
    mySkylink.lifeCycleDelegate = self;
    mySkylink.remotePeerDelegate = self;
    mySkylink.mediaDelegate = self;
    mySkylink.messagesDelegate = self;
    mySkylink.fileTransferDelegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presenceTitleBarViewTapped:) name:TEM_MINIMIZE_PRESENCE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Connect to the room
    if ([mySkylink connectToRoomWithSecret: roomName:self.roomName userInfo:self.myDisplayName])
        NSLog(@"%s::Already connected to a room", __FUNCTION__);
}

- (void)viewDidLayoutSubviews
{
    if (self.statusBarOrientation != [UIApplication sharedApplication].statusBarOrientation) {
        self.statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        // [mySkylink reportRotation];
        
        // Accomodate presence panel frame and control view frame w.r.t. orientation
        presenceNavigationController.view.frame = [self getRespectivePresenceFrame];
        if (presenceNavigationController.minimize) {
            [presenceNavigationController refurbish:YES];
        }
        self.controlView.frame = [self getRespectiveControlViewFrame];
        self.volumeView.frame = [self getRespectiveVolumeViewFrame];
        
        // Accomodate local video view
        if (remoteVideoViewArray.count == 0) {
            self.localVideoView.frame = self.view.bounds;
        } else {
            self.localVideoView.frame = CGRectMake(self.view.bounds.size.width-(TEM_PARENT_PADDING+self.localVideoView.bounds.size.height), CGRectGetMaxY(self.closeButton.frame)+TEM_SIBLING_PADDING, self.localVideoView.bounds.size.height, self.localVideoView.bounds.size.width);
        }
        // [self.localVideoView layoutMySubviews:CGSizeZero];
        
        // Accomodate remote video view
        self.remoteVideoView.frame = self.view.bounds;
        // [self.remoteVideoView layoutMySubviews:CGSizeZero];
        
        [self rearrangeVideoFrames];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark - public methods

/**
 @discussion Send message via data channel if it is destined to a particular peer or broadcast it via signaling otherwise.
 */
- (void)sendChatMessage:(NSString *)message target:(NSString*)target
{
    if (target && ((TEMAppDelegate*)[UIApplication sharedApplication].delegate).appConfig.dataChannel)
        [mySkylink sendDCMessage:message peerId:target];
    else
        [mySkylink sendCustomMessage:message peerId:target];
}

/**
 @discussion Send a broadcast file transfer request if the userId is not given and vice versa.
 */
- (void)startFileTransfer:(NSString*)userId url:(NSURL*)fileURL type:(SKYLINKAssetType)transferType
{
    if (userId) {
        @try {
            [mySkylink sendFileTransferRequest:fileURL assetType:transferType peerId:userId];
        }
        @catch (NSException *exception) {
            [self showAlertWithMessage:@"Another file transfer is in progress with this user. Please try again after the other file transfer is ended. Thanks!"];
        }
    } else {
        [mySkylink sendFileTransferRequest:fileURL assetType:transferType];
    }
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate

/** 
 @discussion First message sent to the delegate upon successful or unsuccessful connection.
 @param connection The underlying connection object.
 @param errorMessage Error message in case the connection is unsuccessful.
 @param isSuccess Flag to specify whether the connection was successful.
 */
- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess
{
    if (isSuccess) {
        NSLog(@"Inside %s", __FUNCTION__);
#if TARGET_IPHONE_SIMULATOR
        TEMRichVideoView *videoView = [[TEMRichVideoView alloc] initWithFrame:self.view.bounds videoView:[UIView new]];
        videoView.isRemote = NO;
        videoView.delegate = self;
        [self.view insertSubview:videoView belowSubview:self.timeLabel];
        self.localVideoView = videoView;
#endif
        
        SKYLINKConnectionConfig *config = ((TEMAppDelegate*)[UIApplication sharedApplication].delegate).appConfig;
        BOOL haveVideo = config.video && config.audio;
        BOOL haveFileTransfer = config.fileTransfer && config.dataChannel;
        if (!haveVideo) {
            NSString *configText = nil;
            if (!config.audio && !haveFileTransfer) {
                configText = @"Chat Only";
            } else if (!config.audio && haveFileTransfer) {
                configText = @"Data Only";
            } else {
                configText = @"Audio Call";
                self.videoButton.enabled = false;
            }
            [self.configLabel setText:configText];
            self.configLabel.hidden = NO;
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Refused!" message:errorMessage delegate:self cancelButtonTitle:@"I've got it!" otherButtonTitles:nil];
        alertView.tag = RoomAlertViewTypeConnectionClosed;
        [alertView show];
    }
}

/** 
 @discussion Upon successful capturing and rendering of the local front camera.
 @param connection The underlying connection object.
 @param userVideoView The video view of the connecting client.
 */
- (void)connection:(SKYLINKConnection*)connection didRenderUserVideo:(UIView*)userVideoView
{
    TEMRichVideoView *videoView = [[TEMRichVideoView alloc] initWithFrame:self.view.bounds videoView:userVideoView];
    videoView.isRemote = NO;
    videoView.delegate = self;
    [self.view insertSubview:videoView belowSubview:self.timeLabel];
    self.localVideoView = videoView;
}

/** 
 @discussion When a remote peer locks/unlocks the room.
 @param connection The underlying connection object.
 @param lockStatus The status of the lock.
 @param peerId The unique id of the peer who originated the action.
 */
- (void)connection:(SKYLINKConnection*)connection didLockTheRoom:(BOOL)lockStatus peerId:(NSString*)peerId
{
    NSString *lockMessage = lockStatus ? @"locked" : @"unlocked";
    [self showToastLabel:[NSString stringWithFormat:@"'%@' has %@ the room!", [connection getUserInfo:peerId], lockMessage]];
    if (lockStatus) {
        [self.lockButton setImage:[UIImage imageNamed:@"unlock"] forState:UIControlStateNormal];
        self.lockButton.myState = 1;
    } else {
        [self.lockButton setImage:[UIImage imageNamed:@"lock"] forState:UIControlStateNormal];
        self.lockButton.myState = 0;
    }
}

/** 
 @discussion When a warning is received from the underlying system.
 @param connection The underlying connection object.
 @param message Warning message from the underlying system.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveWarning:(NSString*)message
{
    NSLog(@"%s::%@", __FUNCTION__, message);
}

/** 
 @discussion When the client is disconnected from the server.
 @param connection The underlying connection object.
 @param errorMessage Message specifying the reason of disconnection.
 */
- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Disconnected!" message:errorMessage delegate:self cancelButtonTitle:@"I've got it!" otherButtonTitles:nil];
    alertView.tag = RoomAlertViewTypeConnectionClosed;
    [alertView show];
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate

/** 
 @discussion When a remote peer joins the room.
 @param connection The underlying connection object.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 @param pmProperties An object defining peer media properties of the joining peer.
 @param peerId The unique id of the joining peer.
 */
- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId
{
    NSString *displayName = [self getDisplayName:userInfo];
    [self showToastLabel:[NSString stringWithFormat:@"'%@' is now in the room!", displayName]];
    if (!presenceNavigationController) {
        remotePeerArray = [NSMutableArray new];
        [self constructPresenceAndControlPanel];
    } else {
        presenceNavigationController.view.hidden = NO;
    }
    [remotePeerArray addObject:peerId];
    [self.presenceTableViewController addParticipant:displayName peerId:peerId];
    [self startTimer];
}

/** 
 @discussion Upon receiving a remote video stream.
 @param connection The underlying connection object.
 @param peerVideoView The video view of the joining peer.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didRenderPeerVideo:(UIView*)peerVideoView peerId:(NSString*)peerId
{
    TEMRichVideoView *videoView = [[TEMRichVideoView alloc] initWithFrame:self.localVideoView.frame videoView:peerVideoView];
    videoView.isRemote = YES;
    videoView.delegate = self;
    videoView.ID = peerId;
    videoView.title = [self getDisplayName:[connection getUserInfo:peerId]];
    
    if (!remoteVideoViewArray)
        remoteVideoViewArray = [NSMutableArray new];
    
    if (remoteVideoViewArray.count == 0) {
        CGFloat localVideoViewWidth = self.localVideoView.bounds.size.width/4;
        CGFloat localVideoViewHeight = self.localVideoView.bounds.size.height/4;
        [UIView animateWithDuration:0.3 animations:^{
            self.localVideoView.frame = CGRectMake(self.view.bounds.size.width-(TEM_PARENT_PADDING+localVideoViewWidth), CGRectGetMaxY(self.closeButton.frame)+TEM_SIBLING_PADDING, localVideoViewWidth, localVideoViewHeight);
        } completion:^(BOOL finished) {
            // [self.localVideoView layoutMySubviews:CGSizeZero];
        }];
        
        self.remoteVideoView = videoView;
    } else if (remoteVideoViewArray.count == 1) {
        videoView.frame = CGRectMake(videoView.frame.origin.x, CGRectGetMinY(self.controlView.frame)-(TEM_SIBLING_PADDING+videoView.frame.size.height), videoView.frame.size.width, videoView.frame.size.height);
    } else {
        NSInteger totalThumbnails = remoteVideoViewArray.count;
        CGFloat videoViewFrameX = self.view.bounds.size.width - (TEM_PARENT_PADDING + (totalThumbnails-1)*TEM_SIBLING_PADDING + totalThumbnails*videoView.bounds.size.width);
        videoView.frame = CGRectMake(videoViewFrameX, CGRectGetMinY(self.controlView.frame)-(TEM_SIBLING_PADDING+videoView.frame.size.height), videoView.frame.size.width, videoView.frame.size.height);
    }
    
    [remoteVideoViewArray addObject:videoView];
    [self.view insertSubview:videoView belowSubview:self.localVideoView];
}

/** 
 @discussion Upon receiving an update about a user info.
 @param connection The underlying connection object.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveUserInfo:(id)userInfo peerId:(NSString*)peerId
{
    NSString *nick = [self getDisplayName:userInfo];
    NSString *oldNick = [self.presenceTableViewController updateParticipant:nick peerId:peerId];
    [self showToastLabel:[NSString stringWithFormat:@"'%@' is now known as '%@'", oldNick, nick]];
}

/** 
 @discussion When a peer has left the room implictly or explicitly.
 @param connection The underlying connection object.
 @param errorMessage Error message in case the peer is left due to some error.
 @param peerId The unique id of the leaving peer.
 */
- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId
{
    [self showToastLabel:[NSString stringWithFormat:@"'%@' has left the room!", [self getDisplayName:[connection getUserInfo:peerId]]]];
    for (NSString *remotePeerId in remotePeerArray)
        if ([peerId caseInsensitiveCompare:remotePeerId] == NSOrderedSame) {
            [remotePeerArray removeObject:peerId];
            [self.presenceTableViewController deleteParticipant:peerId];
            if (remotePeerArray.count == 0) {
                presenceNavigationController.view.hidden = YES;
                presenceNavigationController.minimize = YES;
                // Unmute the audio if everybody has left the room.
                [mySkylink muteAudio:FALSE];
                [self.audioButton setImage:[UIImage imageNamed:@"disable_audio"] forState:UIControlStateNormal];
                self.audioButton.myState = 0;
                // Unmute the video if everybody has left the room.
                [mySkylink muteVideo:FALSE];
                [self.videoButton setImage:[UIImage imageNamed:@"disable_camera"] forState:UIControlStateNormal];
                self.videoButton.myState = 0;
                [self stopTimer];
            }
            break;
        }
    for (TEMRichVideoView *videoView in remoteVideoViewArray) {
        if ([videoView.ID caseInsensitiveCompare:peerId] == NSOrderedSame) {
            [self deleteRemoteVideoView:videoView];
            break;
        }
    }
}

#pragma mark - SKYLINKConnectionMediaDelegate

/** 
 @discussion When the dimension of the video view are changed.
 @param connection The underlying connection object.
 @param videoSize The size of the respective video.
 @param videoView The video view for which the size was sent.
 */
- (void)connection:(SKYLINKConnection*)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView*)videoView
{
    if (videoView == [self.localVideoView getRenderSurface]) {
        [self.localVideoView layoutSubviews:videoSize];
        return;
    }
    
    for (TEMRichVideoView *vidView in remoteVideoViewArray)
        if ([vidView getRenderSurface] == videoView) {
            [vidView layoutSubviews:videoSize];
            break;
        }
}

/** 
 @discussion When a peer mutes/unmutes its audio.
 @param connection The underlying connection object.
 @param isMuted Flag to specify whether the audio is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didToggleAudio:(BOOL)isMuted peerId:(NSString*)peerId
{
    [self showToastLabel:[NSString stringWithFormat:@"%@'s audio is %@ now", [self getDisplayName:[connection getUserInfo:peerId]], (isMuted ? @"muted" : @"unmuted")]];
}

/** 
 @discussion When a peer mutes/unmutes its video.
 @param connection The underlying connection object.
 @param isMuted Flat to specify whether the video is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didToggleVideo:(BOOL)isMuted peerId:(NSString*)peerId
{
    for (TEMRichVideoView *videoView in remoteVideoViewArray)
        if ([videoView.ID caseInsensitiveCompare:peerId] == NSOrderedSame) {
            videoView.isEnabled = !isMuted;
            break;
        }
    [self showToastLabel:[NSString stringWithFormat:@"%@'s video is %@ now", [self getDisplayName:[connection getUserInfo:peerId]], (isMuted ? @"muted" : @"unmuted")]];
}

#pragma mark - SKYLINKConnectionMessagesDelegate

/** 
 @discussion Upon receiving a private or public message.
 @param connection The underlying connection object.
 @param message User defined message. May be an NSString, NSDictionary or NSArray.
 @param isPublic Flag to specify whether the message was a broadcast.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveCustomMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId
{
    [self.presenceTableViewController addChatMessage:message nick:[self getDisplayName:[connection getUserInfo:peerId]] peerId:peerId isPublic:isPublic];
    if (presenceNavigationController.minimize)
        [self.presenceTableViewController highlightPanelButton];
}

/** 
 @discussion Upon receiving a data channel chat message.
 @param connection The underlying connection object.
 @param message User defined message. May be an NSString, NSDictionary or NSArray.
 @param isPublic Flag to specify whether the message was a broadcast.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveDCMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId
{
    [self.presenceTableViewController addChatMessage:message nick:[self getDisplayName:[connection getUserInfo:peerId]] peerId:peerId isPublic:isPublic];
    if (presenceNavigationController.minimize)
        [self.presenceTableViewController highlightPanelButton];
}

/** 
 @discussion Upon receiving binary data on data channel.
 @param connection The underlying connection object.
 @param data Binary data.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveBinaryData:(NSData*)data peerId:(NSString*)peerId
{
    NSLog(@"INFO::Received binary data of length %i from %@", data.length, peerId);
}

#pragma mark - SKYLINKConnectionFileTransferDelegate

/** 
 @discussion Upon receiving a file transfer request from a peer.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveRequest:(NSString*)filename peerId:(NSString*)peerId
{
    TEMFileAlertView *alertView = [[TEMFileAlertView alloc] initWithTitle:@"Permission!" message:[NSString stringWithFormat:@"The user '%@' wants to send you a file with name '%@'. Do you want to accept it?", [self getDisplayName:[connection getUserInfo:peerId]], filename] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
    alertView.tag = RoomAlertViewTypeFileRequest;
    alertView.remotePeerId = peerId;
    alertView.fileName = filename;
    [alertView show];
}

/**
 @discussion Upon receiving a file transfer permission from a peer.
 @param connection The underlying connection object.
 @param isPermitted Flag to specify whether the request was accepted.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceivePermission:(BOOL)isPermitted filename:(NSString*)filename peerId:(NSString*)peerId
{
    if (isPermitted) {
        [self addProgressView:peerId];
    } else {
        [self showAlertWithMessage:[NSString stringWithFormat:@"We are sorry that the user '%@' has refused to accept your '%@' sending request", [self getDisplayName:[connection getUserInfo:peerId]], filename]];
    }
}

/** 
 @discussion When the file being transferred is halted.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param message The message specifying reason for the file transfer drop.
 @param isExplicit Flag to specify whether the transfer was halted explicity by the sender.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didDropTransfer:(NSString*)filename reason:(NSString*)message isExplicit:(BOOL)isExplicit peerId:(NSString*)peerId
{
    NSString *userMessage = [NSString stringWithFormat:@"'%@' has canceled the file being transferred", [self getDisplayName:[connection getUserInfo:peerId]]];
    if (isExplicit) {
        [self showToastLabel:userMessage];
    } else {
        [self showAlertWithMessage:message];
    }
    [self removeProgressView:peerId];
}

/** 
 @discussion Upon file transfer completion.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param fileData NSData object holding the data transferred.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didCompleteTransfer:(NSString*)filename fileData:(NSData*)fileData peerId:(NSString*)peerId
{
    if (fileData) {
        NSString *fileExtension = [[filename componentsSeparatedByString:@"."] lastObject];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([self isImage:fileExtension] && [UIImage imageWithData:fileData]) {
            UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(filename));
        } else {
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:filename];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
            
            NSError *wError;
            [fileData writeToFile:filePath options:NSDataWritingAtomic error:&wError];
            if (wError) {
                NSLog(@"%s::Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
            } else {
                if ([self isMovie:fileExtension] && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    [[ALAssetsLibrary new] writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:filePath] completionBlock:^(NSURL *assetURL, NSError *error){
                        if (error) NSLog(@"%s::Error while saving '%@'->%@", __FUNCTION__, filename, error.localizedDescription);
                        else [self removeFileAtPath:filePath];
                    }];
                }
            }
        }
    }
    [self removeProgressView:peerId];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"%s::Error while saving '%@'->%@", __FUNCTION__, contextInfo, error.localizedDescription);
        
        NSLog(@"%s::Now try saving to the Documents Directory", __FUNCTION__);
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[pathArray firstObject] stringByAppendingPathComponent:(__bridge NSString *)(contextInfo)];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![self removeFileAtPath:filePath]) return;
        
        NSError *wError;
        [UIImagePNGRepresentation(image) writeToFile:filePath options:NSDataWritingAtomic error:&wError];
        if (wError)
            NSLog(@"%s::Error while writing '%@'->%@", __FUNCTION__, filePath, wError.localizedDescription);
    } else {
        NSLog(@"%s::Image saved successfully", __FUNCTION__);
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case RoomAlertViewTypeConnectionClosed:
            [self closeButtonTapped:nil];
            break;
        case RoomAlertViewTypeFileRequest:
        {
            TEMFileAlertView *myAlertView = (TEMFileAlertView*)alertView;
            if (buttonIndex == 0) {
                [self addProgressView:myAlertView.remotePeerId];
                // Accept the file transfer.
                [mySkylink acceptFileTransfer:YES filename:myAlertView.fileName peerId:myAlertView.remotePeerId];
            } else {
                // Refuse the file transfer.
                [mySkylink acceptFileTransfer:NO filename:myAlertView.fileName peerId:myAlertView.remotePeerId];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - TEMVideoViewDelegate

- (void)videoViewIsTapped:(TEMVideoView *)videoView
{
    [self.view endEditing:YES];
    if (videoView == self.remoteVideoView || videoView == self.localVideoView) {
        if (remoteVideoViewArray.count > 0)
            [self showControlView];
    } else {
        [self swapVideosAnimated:videoView animated:YES];
    }
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardRect;
    [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    keyboardRect = [self.view convertRect:keyboardRect fromView:((TEMAppDelegate*)[UIApplication sharedApplication].delegate).window];
    
    CGFloat keyboardHeight = keyboardRect.size.height;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        ;//keyboardHeight = keyboardRect.size.width;
    CGRect adjustedFrame = [self getRespectivePresenceFrame];
    adjustedFrame = CGRectMake(adjustedFrame.origin.x, adjustedFrame.origin.y-keyboardHeight, adjustedFrame.size.width, adjustedFrame.size.height);
    
    [UIView animateWithDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        presenceNavigationController.view.frame = adjustedFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [UIView animateWithDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        presenceNavigationController.view.frame = [self getRespectivePresenceFrame];
    }];
}

#pragma mark - IBAction

- (IBAction)closeButtonTapped:(id)sender {
    [remotePeerArray removeAllObjects];
    remotePeerArray = nil;
    
    for (TEMRichVideoView *videoView in remoteVideoViewArray)
        [videoView removeFromSuperview];
    [remoteVideoViewArray removeAllObjects];
    remoteVideoViewArray = nil;
    self.remoteVideoView = nil;
    
    [self.controlView removeFromSuperview];
    self.controlView = nil;

    [presenceNavigationController.view removeFromSuperview];
    presenceNavigationController = nil;
    self.presenceTableViewController = nil;
    
    [self stopTimer];
    [self.localVideoView removeFromSuperview];
    self.localVideoView = nil;
        
    [self dismissViewControllerAnimated:YES completion:^{
        // Disconnect from the room.
        [mySkylink disconnect];
        mySkylink = nil;
        ((TEMAppDelegate*)[UIApplication sharedApplication].delegate).roomViewController = nil;
    }];
}

- (IBAction)controlViewButtonTapped:(id)sender {
    TEMControlButton *controlButton = (TEMControlButton*)sender;
    switch (controlButton.tag) {
        case 0:
            [mySkylink switchCamera];
            break;
        case 1:
            if (controlButton.myState == 0) {
                [controlButton setImage:[UIImage imageNamed:@"enable_camera"] forState:UIControlStateNormal];
                controlButton.myState = 1;
                // Mute video
                [mySkylink muteVideo:TRUE];
            } else {
                [controlButton setImage:[UIImage imageNamed:@"disable_camera"] forState:UIControlStateNormal];
                controlButton.myState = 0;
                // Unmute video
                [mySkylink muteVideo:FALSE];
            }
            break;
        case 2:
            if (controlButton.myState == 0) {
                [controlButton setImage:[UIImage imageNamed:@"enable_audio"] forState:UIControlStateNormal];
                controlButton.myState = 1;
                // Mute audio
                [mySkylink muteAudio:TRUE];
            } else {
                [controlButton setImage:[UIImage imageNamed:@"disable_audio"] forState:UIControlStateNormal];
                controlButton.myState = 0;
                // Unmute audio
                [mySkylink muteAudio:FALSE];
            }
            break;
        case 3:
            if (controlButton.myState == 0) {
                [controlButton setImage:[UIImage imageNamed:@"unlock"] forState:UIControlStateNormal];
                controlButton.myState = 1;
                // Lock the room
                [mySkylink lockTheRoom];
            } else {
                [controlButton setImage:[UIImage imageNamed:@"lock"] forState:UIControlStateNormal];
                controlButton.myState = 0;
                // Unlock the room
                [mySkylink unlockTheRoom];
            }
            break;
        default:
            break;
    }
}

- (IBAction)presenceTitleBarViewTapped:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        presenceNavigationController.minimize = !presenceNavigationController.minimize;
    }];
}

- (IBAction)backGroundTapped:(id)sender {
    [self showControlView];
}

#pragma mark - private methods

- (void)addProgressView:(NSString*)remotePeerId
{
    for (TEMRichVideoView *videoView in remoteVideoViewArray)
        if ([remotePeerId caseInsensitiveCompare:videoView.ID] == NSOrderedSame) {
            [videoView addProgressView];
            break;
        }
}

- (void)constructPresenceAndControlPanel
{
    // initialize presence panel
    TEMPresenceTableViewController *tableViewController = [[TEMPresenceTableViewController alloc] initWithNibName:nil bundle:nil];
    presenceNavigationController = [[TEMPresenceNavigationController alloc] initWithRootViewController:tableViewController];
    self.presenceTableViewController = tableViewController;
    
    presenceNavigationController.view.frame = [self getRespectivePresenceFrame];
    [self.view addSubview:presenceNavigationController.view];
    // presenceNavigationController.minimize = YES;
    
    // initialize control panel
    self.controlView.frame = [self getRespectiveControlViewFrame];
    [self.view insertSubview:self.controlView belowSubview:presenceNavigationController.view];
    
    if (!((TEMAppDelegate*)[UIApplication sharedApplication].delegate).isPad) {
        MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame:[self getRespectiveVolumeViewFrame]];
        myVolumeView.showsVolumeSlider = NO;
        myVolumeView.alpha = 0.0;
        [self.view addSubview:myVolumeView];
        self.volumeView = myVolumeView;
    }
}

- (BOOL)deleteRemoteVideoView:(UIView*)videoView
{
    if (remoteVideoViewArray.count == 1) {
        [videoView removeFromSuperview];
        [remoteVideoViewArray removeObject:videoView];
        [UIView animateWithDuration:0.3 animations:^{
            self.localVideoView.frame = self.view.bounds;
        } completion:^(BOOL finished) {
            // [self.localVideoView layoutMySubviews:CGSizeZero];
        }];
        return TRUE;
    } else {
        if (videoView == self.remoteVideoView) {
            TEMRichVideoView *lastVideoView = [remoteVideoViewArray lastObject];
            if (lastVideoView == self.remoteVideoView)
                lastVideoView = [remoteVideoViewArray objectAtIndex:remoteVideoViewArray.count-2];
            [self swapVideosAnimated:lastVideoView animated:NO];
            [videoView removeFromSuperview];
            [remoteVideoViewArray removeObject:videoView];
        } else {
            [videoView removeFromSuperview];
            [remoteVideoViewArray removeObject:videoView];
            [self rearrangeVideoFrames];
        }
        return FALSE;
    }
}

- (void)increaseTimerCount
{
    NSUInteger h = (++self.timerCount / 3600);
    NSUInteger m = ((NSUInteger)(self.timerCount / 60)) % 60;
    NSUInteger s = ((NSUInteger) self.timerCount) % 60;
    self.timeLabel.text = [NSString stringWithFormat:@"%lu:%02lu:%02lu", (unsigned long)h, (unsigned long)m, (unsigned long)s];
}

- (NSString*)getDisplayName:(id)info
{
    if ([info isKindOfClass:[NSString class]]) {
        return info;
    } else {
        return [info objectForKey:@"displayName"];
    }
}

- (CGRect)getRespectiveControlViewFrame
{
    CGFloat x = 0.0, y = 0.0;
    if (((TEMAppDelegate*)[UIApplication sharedApplication].delegate).isPad) {
        x = CGRectGetMaxX(presenceNavigationController.view.frame) + ((self.view.bounds.size.width - presenceNavigationController.view.frame.size.width) - self.controlView.bounds.size.width) / 2;
        y = (presenceNavigationController.minimize) ? presenceNavigationController.view.frame.origin.y : [presenceNavigationController getMinimizedY];
    } else {
        if (UIInterfaceOrientationIsPortrait(self.statusBarOrientation)) {
            x = (self.view.bounds.size.width - self.controlView.bounds.size.width) / 2;
            y = (presenceNavigationController.minimize ? presenceNavigationController.view.frame.origin.y : [presenceNavigationController getMinimizedY]) - (TEM_SIBLING_PADDING+self.controlView.bounds.size.height);
        } else {
            x = CGRectGetMaxX(presenceNavigationController.view.frame) + ((self.view.bounds.size.width - presenceNavigationController.view.frame.size.width) - self.controlView.bounds.size.width) / 2;
            y = presenceNavigationController.minimize ? presenceNavigationController.view.frame.origin.y : [presenceNavigationController getMinimizedY];
        }
    }
    return CGRectMake(x, y, self.controlView.bounds.size.width, self.controlView.bounds.size.height);
}

- (CGRect)getRespectivePresenceFrame
{
    CGRect screenBounds = CGRectZero;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        screenBounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;
    else
        screenBounds = [UIScreen mainScreen].bounds;
    CGRect presenceNavigationFrame = CGRectZero;
    if (((TEMAppDelegate*)[UIApplication sharedApplication].delegate).isPad) {
        CGSize size = CGSizeMake(screenBounds.size.width/3, screenBounds.size.width/2);
        presenceNavigationFrame = CGRectMake(0, self.view.bounds.size.height-size.height, size.width, size.height);
    } else {
        presenceNavigationFrame = UIInterfaceOrientationIsPortrait(self.statusBarOrientation) ? CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) : CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.width);
    }
    return presenceNavigationFrame;
}

- (CGRect)getRespectiveVolumeViewFrame
{
    CGFloat h = 31;
    return CGRectMake(self.controlView.frame.origin.x, self.controlView.frame.origin.y-(TEM_SIBLING_PADDING+h), self.controlView.bounds.size.width, h);
}

- (void)hideControlView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.volumeView.alpha = self.controlView.alpha = 0.0;
    }];
}

- (void)hideToastLabel
{
    [UIView animateWithDuration:0.3 animations:^{
        self.toastLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.toastLabel.text = @"";
    }];
}

- (BOOL)isImage:(NSString*)extension
{
    return ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpe"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jfif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jfi"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jp2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"j2k"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpf"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpx"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpm"] == NSOrderedSame || [extension caseInsensitiveCompare:@"tiff"] == NSOrderedSame || [extension caseInsensitiveCompare:@"tif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pict"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pct"] == NSOrderedSame || [extension caseInsensitiveCompare:@"pic"] == NSOrderedSame || [extension caseInsensitiveCompare:@"gif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"png"] == NSOrderedSame || [extension caseInsensitiveCompare:@"qtif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"icns"] == NSOrderedSame || [extension caseInsensitiveCompare:@"bmp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"bmpf"] == NSOrderedSame || [extension caseInsensitiveCompare:@"ico"] == NSOrderedSame || [extension caseInsensitiveCompare:@"cur"] == NSOrderedSame || [extension caseInsensitiveCompare:@"xbm"] == NSOrderedSame);
}

- (BOOL)isMovie:(NSString*)extension
{
    return ([extension caseInsensitiveCompare:@"mpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mpeg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"m1v"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mpv"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gpp"] == NSOrderedSame || [extension caseInsensitiveCompare:@"sdv"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3g2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"3gp2"] == NSOrderedSame || [extension caseInsensitiveCompare:@"m4v"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mp4"] == NSOrderedSame || [extension caseInsensitiveCompare:@"mov"] == NSOrderedSame || [extension caseInsensitiveCompare:@"qt"] == NSOrderedSame);
}

- (void)rearrangeVideoFrames
{
    // Here you rearrange the remote video view frames
    NSMutableArray *tempViewArray = [NSMutableArray new];
    for (TEMRichVideoView *vidView in remoteVideoViewArray)
        if (vidView != self.remoteVideoView)
            [tempViewArray addObject:vidView];
    
    CGFloat w = self.localVideoView.bounds.size.width;
    CGFloat h = self.localVideoView.bounds.size.height;
    CGFloat x = self.view.bounds.size.width-TEM_PARENT_PADDING;
    CGFloat y = CGRectGetMinY(self.controlView.frame)-(TEM_SIBLING_PADDING+h);
    for (int i = 0; i < tempViewArray.count; i++, x-=TEM_SIBLING_PADDING) {
        TEMRichVideoView *videoView = [tempViewArray objectAtIndex:i];
        x = x - w;
        videoView.frame = CGRectMake(x, y, w, h);
        // [videoView layoutMySubviews:CGSizeZero];
    }
}

- (BOOL)removeFileAtPath:(NSString*)filePath
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"%s::Error while removing '%@'->%@", __FUNCTION__, filePath, error.localizedDescription);
        return false;
    } else {
        return true;
    }
}

- (void)removeProgressView:(NSString*)remotePeerId
{
    for (TEMRichVideoView *videoView in remoteVideoViewArray)
        if ([remotePeerId caseInsensitiveCompare:videoView.ID] == NSOrderedSame) {
            [videoView removeProgressView];
            break;
        }
}

- (void)showAlertWithMessage:(NSString*)message
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    self.volumeView.alpha = self.controlView.alpha = 1.0;
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:3.0];
}

- (void)showToastLabel:(NSString*)message
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToastLabel) object:nil];
    self.toastLabel.text = message;
    self.toastLabel.alpha = 1.0;
    [self performSelector:@selector(hideToastLabel) withObject:nil afterDelay:3.0];
}

- (void)startTimer
{
    self.timeLabel.hidden = NO;
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(increaseTimerCount) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)stopTimer
{
    [timer invalidate];
    timer = nil;
    self.timerCount = 0;
    self.timeLabel.text = @"00:00:00";
    self.timeLabel.hidden = YES;
}

- (void)swapVideosAnimated:(TEMRichVideoView*)videoView animated:(BOOL)animated
{
    CGRect bigFrame = self.remoteVideoView.frame;
    CGRect smallFrame = videoView.frame;
    CGFloat duration = animated ? 0.3 : 0.0;
    
    videoView.lblTitle.hidden = self.remoteVideoView.lblTitle.hidden = YES;
    self.remoteVideoView.alpha = 0;
    [UIView animateWithDuration:duration animations:^{
        videoView.frame = bigFrame;
        self.remoteVideoView.frame = smallFrame;
        self.remoteVideoView.alpha = 1;
    } completion:^(BOOL finished) {
        [self.view sendSubviewToBack:videoView];
        TEMRichVideoView *tmpVideoView = self.remoteVideoView;
        self.remoteVideoView = videoView;
        // [self.remoteVideoView layoutMySubviews:CGSizeZero];
        // [tmpVideoView layoutMySubviews:CGSizeZero];
        self.remoteVideoView.lblTitle.hidden = tmpVideoView.lblTitle.hidden = NO;
    }];
}

@end
