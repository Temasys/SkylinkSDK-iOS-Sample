//
//  AudioCallViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 07/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "AudioCallViewController.h"


#define ROOM_NAME  @"AUDIO-CALL-ROOM"


@interface AudioCallViewController ()
// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// Other properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSMutableArray *remotePeerArray;
@end


@implementation AudioCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Audio Call";
    self.remotePeerArray = [[NSMutableArray alloc] init];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = NO;
    config.audio = YES;
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.mediaDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
    [SKYLINKConnection setVerbose:TRUE];
    
    // connectToRoomWithCredentials example
    NSDictionary *credInfos = @{@"startTime" : [NSDate date], @"duration" : [NSNumber numberWithFloat:2.0f]};
    NSString *credential = [SKYLINKConnection calculateCredentials:ROOM_NAME duration:[credInfos[@"duration"] floatValue] startTime:credInfos[@"startTime"] secret:self.skylinkApiSecret];
    [self.skylinkConnection connectToRoomWithCredentials:@{@"credential" : credential, @"startTime" : credInfos[@"startTime"], @"duration" : credInfos[@"duration"]} roomName:ROOM_NAME userInfo:nil];
}

-(void)disconnect {
    if (self.skylinkConnection) [self.skylinkConnection disconnect:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

-(void)showInfo {
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ infos", NSStringFromClass([self class])] message:[NSString stringWithFormat:@"\nRoom name:\n%@\n\nLocal ID:\n%@\n\nKey: •••••%@\n\nSkylink version %@", ROOM_NAME, self.skylinkConnection.myPeerId, [self.skylinkApiKey substringFromIndex: [self.skylinkApiKey length] - 7],  [SKYLINKConnection getSkylinkVersion]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate

- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Inside %s", __FUNCTION__);
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connection failed" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
}

- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - SKYLINKConnectionMediaDelegate

- (void)connection:(SKYLINKConnection *)connection didToggleAudio:(BOOL)isMuted peerId:(NSString *)peerId {
    for (NSDictionary *peerDic in self.remotePeerArray) {
        if ([peerDic[@"id"] isEqualToString:peerId]) {
            [self.remotePeerArray removeObject:peerDic];
            [self.remotePeerArray addObject:@{@"id" : peerId, @"isAudioMuted" : [NSNumber numberWithBool:isMuted]}];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate

- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ joigned the room.", peerId);
    [self.remotePeerArray addObject:@{@"id" : peerId, @"isAudioMuted" : [NSNumber numberWithBool:pmProperties.isAudioMuted]}];
    [self.tableView reloadData];
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    NSLog(@"Peer with id %@ left the room with message: %@", peerId, errorMessage);
    for (NSDictionary *peerDic in self.remotePeerArray) {
        if ([peerDic[@"id"] isEqualToString:peerId]) [self.remotePeerArray removeObject:peerDic];
    }
    [self.tableView reloadData];
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
    cell.textLabel.text = peerDic[@"id"];
    cell.detailTextLabel.text = [peerDic[@"isAudioMuted"] boolValue] ? @"Audio muted" : @" ";
    
    cell.backgroundColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBAction

- (IBAction)switchAudioTap:(UIButton *)sender {
    [sender setTitle:(!self.skylinkConnection.isAudioMuted ? @"Unmute microphone" : @"Mute microphone") forState:UIControlStateNormal];
    [self.skylinkConnection muteAudio:!self.skylinkConnection.isAudioMuted];
}

@end


