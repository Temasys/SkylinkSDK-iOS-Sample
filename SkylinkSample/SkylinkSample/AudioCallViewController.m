//
//  AudioCallViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 07/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "AudioCallViewController.h"
#import "Constant.h"

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_AUDIOCALL"]


@interface AudioCallViewController ()<SKYLINKConnectionMediaDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// Other properties
@property (strong, nonatomic) NSMutableArray *remotePeerArray;
@end


@implementation AudioCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Audio Call";
    self.remotePeerArray = [NSMutableArray array];
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoSendConfig:AudioVideoConfig_AUDIO_ONLY];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_AUDIO_ONLY];
    
    // Creating SKYLINKConnection
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.mediaDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;

    // Connecting to a room
    // connectToRoomWithCredentials example
//    NSDictionary *credInfos = @{@"startTime" : [NSDate date], @"duration" : [NSNumber numberWithFloat:24.000f]};
//    NSString *credential = [SKYLINKConnection calculateCredentials:ROOM_AUDIO duration:credInfos[@"duration"] startTime:credInfos[@"startTime"] secret:APP_SECRET];
//    [_skylinkConnection connectToRoomWithStringURL:credential userData:USER_NAME callback:nil];
    [self joinRoom];
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection
{
    MyLog(@"Inside %s", __FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        [self startLocalAudio];
    });
}
- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage
{
    [UIAlertController showAlertWithAutoDisappearTitle:@"Connection failed" message:errorMessage duration:3 onViewController:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)connection:(SKYLINKConnection *)connection didDisconnectFromRoomWithSkylinkEvent:(NSDictionary *)skylinkEvent contextDescription:(NSString *)contextDescription
{
//    showAlertAutoDismiss(@"Disconnected", skylinkEvent.description, 3, self);
//    [UIAlertController showAlertWithAutoDisappearTitle:@"Disconnected" message:skylinkEvent.description duration:3 onViewController:self];
//    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - SKYLINKConnectionMediaDelegate

- (void)connection:(SKYLINKConnection *)connection didToggleAudio:(BOOL)isMuted peerId:(NSString *)peerId {
    NSArray *enumarateArray = [self.remotePeerArray copy];
    for (NSDictionary *peerDic in enumarateArray) {
        if ([peerDic[@"id"] isEqualToString:peerId]) {
            [self.remotePeerArray removeObject:peerDic];
            [self.remotePeerArray addObject:@{@"id" : peerId, @"isAudioMuted" : [NSNumber numberWithBool:isMuted]}];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    MyLog(@"Peer with id %@ joigned the room.", remotePeerId);
    [self.remotePeerArray addObject:@{@"id" : remotePeerId, @"isAudioMuted" : @(NO), @"nickname" : ([userInfo isKindOfClass:[NSString class]]) ? userInfo : @""}];
    [self.tableView reloadData];
}

- (void)connection:(SKYLINKConnection *)connection didDisconnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    MyLog(@"Peer with id %@ left the room with userInfo: %@", remotePeerId, userInfo);
    NSDictionary *dicToRemove;
    for (NSDictionary *peerDic in self.remotePeerArray)
        if ([peerDic[@"id"] isEqualToString:remotePeerId]) dicToRemove = peerDic;
    [self.remotePeerArray removeObject:dicToRemove];
    [self.tableView reloadData];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerUserData:(id)userData remotePeerId:(NSString *)remotePeerId
{
    
}
#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%lu peer(s) connected", (unsigned long)self.remotePeerArray.count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.remotePeerArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACpeerCell"];
    
    NSDictionary *peerDic = [self.remotePeerArray objectAtIndex:indexPath.row];
    cell.textLabel.text = peerDic[@"nickname"] ? peerDic[@"nickname"] : [NSString stringWithFormat:@"Peer %ld", (long)indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ID: %@ %@", peerDic[@"id"], [peerDic[@"isAudioMuted"] boolValue] ? @" - Audio muted" : @""];
    
    cell.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.00]; // iPads does not use storyboard bg color value
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBAction

- (IBAction)switchAudioTap:(UIButton *)sender {
    [sender setTitle:(!_skylinkConnection.isAudioMuted ? @"Unmute microphone" : @"Mute microphone") forState:UIControlStateNormal];
    [_skylinkConnection muteAudio:!_skylinkConnection.isAudioMuted];
}

- (void)startLocalAudio
{
    [_skylinkConnection createLocalMediaWithMediaDevice:SKYLINKMediaDeviceMicrophone mediaMetadata:nil callback:^(NSError * _Nullable error) {
        if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
    }];
}

- (void)connection:(SKYLINKConnection *)connection didChangeSkylinkMedia:(SKYLINKMedia *)skylinkMedia peerId:(NSString *)peerId
{
    if (skylinkMedia.skylinkMediaType == SKYLINKMediaTypeAudio) {
        
    }
}
@end


