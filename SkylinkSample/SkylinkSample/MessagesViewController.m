//
//  MessagesViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 04/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "MessagesViewController.h"
#import "UIAlertView+Blocks.h"


#define ROOM_NAME  @"MESSAGES-ROOM"


@interface MessagesViewController ()
// IBOutlets
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *isPublicSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *messageTypeSegmentControl;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UIButton *peersButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// Properties
@property (strong, nonatomic) SKYLINKConnection *skylinkConnection;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *peers;

@end


@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Messages";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cancel.png"] style:UIBarButtonItemStylePlain target:self action:@selector(disconnect)];
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    self.messages = [[NSMutableArray alloc] initWithArray:@[]];
    self.peers = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    [self updatePeersButtonTitle];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = NO;
    config.audio = NO;
    config.fileTransfer = NO;
    config.dataChannel = YES; // for data chanel messages
    
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:self.skylinkApiKey];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.messagesDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
#ifdef DEBUG
    [SKYLINKConnection setVerbose:TRUE];
#endif
    [self.skylinkConnection connectToRoomWithSecret:self.skylinkApiSecret roomName:ROOM_NAME userInfo:nil]; // a nickname could be sent here via userInfo cf the implementation of - (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId
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
        dispatch_async(dispatch_get_main_queue(), ^{
            self.messageTextField.enabled = YES;
            self.messageTextField.hidden = NO;
            self.nicknameTextField.enabled = YES;
            self.nicknameTextField.hidden = NO;
            self.sendButton.enabled = YES;
            self.sendButton.hidden = NO;
            [self.messageTextField becomeFirstResponder];
        });
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



#pragma mark - SKYLINKConnectionMessagesDelegate

- (void)connection:(SKYLINKConnection*)connection didReceiveCustomMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId {
    [self.messages insertObject:@{@"message" : message, // could also be custom structure like message[@"message"]
                                  @"isPublic" : [NSNumber numberWithBool:isPublic],
                                  @"peerId" : peerId,
                                  @"type" : @"signaling server"
                                  }
                        atIndex:0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)connection:(SKYLINKConnection*)connection didReceiveDCMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId {
    [self.messages insertObject:@{@"message" : message,
                                  @"isPublic" : [NSNumber numberWithBool:isPublic],
                                  @"peerId" : peerId,
                                  @"type" : @"P2P"
                                  }
                        atIndex:0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade]; // equivalent of [self.tableView reloadData]; + [self.tableView scrollsToTop]; but with an animation
}

- (void)connection:(SKYLINKConnection*)connection didReceiveBinaryData:(NSData*)data peerId:(NSString*)peerId {
    id maybeString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.messages insertObject:@{@"message" : (maybeString && [maybeString isKindOfClass:[NSString class]]) ? ((NSString *)maybeString) : [NSString stringWithFormat:@"Binary data of length %lu", (unsigned long)data.length], // if received by the Android sample app, the length will be printed as message
                                  @"isPublic" :[NSNumber numberWithBool:NO], // always private if received by iOS sample app
                                  @"peerId" : peerId,
                                  @"type" : @"binary data"
                                  }
                        atIndex:0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - SKYLINKConnectionRemotePeerDelegate

- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId {
    NSString *displayNickname = (userInfo && [userInfo isKindOfClass:[NSDictionary class]] && userInfo[@"nickname"]) ? userInfo[@"nickname"] : [NSString stringWithFormat:@"ID: %@", peerId];
    [self.peers addEntriesFromDictionary:@{peerId:displayNickname}];
    [self updatePeersButtonTitle];
}

- (void)connection:(SKYLINKConnection*)connection didReceiveUserInfo:(id)userInfo peerId:(NSString*)peerId {
    [self.peers removeObjectForKey:peerId];
    NSString *displayNickname = (userInfo[@"nickname"]) ? userInfo[@"nickname"] : [NSString stringWithFormat:@"ID: %@", peerId];
    [self.peers addEntriesFromDictionary:@{peerId:displayNickname}];
    [self updatePeersButtonTitle];
    [self.tableView reloadData]; // will reload the sender label
}

- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId {
    NSLog(@"Peer with ID %@ left with message: %@", peerId, errorMessage);
    [self.peers removeObjectForKey:peerId];
    [self updatePeersButtonTitle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell"];
    
    NSDictionary *message = [self.messages objectAtIndex:indexPath.row];
    
    cell.textLabel.text = message[@"message"];
    if ([message[@"peerId"] isEqualToString:self.skylinkConnection.myPeerId]) {
        cell.detailTextLabel.text = [message[@"isPublic"] boolValue] ? @"Sent to all" : @"Sent privately";
        cell.backgroundColor = [UIColor colorWithRed:0.71 green:1 blue:0.5 alpha:1];
    }
    else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"From %@ via %@ • %@",
                                     (self.peers[message[@"peerId"]]) ? self.peers[message[@"peerId"]] : message[@"peerId"],
                                     message[@"type"],
                                     [message[@"isPublic"] boolValue] ? @"Public" : @"Private"
                                     ];
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *message = [self.messages objectAtIndex:indexPath.row];
    NSString *messageDetails = [NSString stringWithFormat:@"Message:\n%@\n\nFrom :\n%@\n\n%@", //@"Message:\n%@\n\nFrom %@\n\n%@n\n%@",
                                message[@"message"],
                                [message[@"peerId"] stringByAppendingString:([message[@"peerId"] isEqualToString:self.skylinkConnection.myPeerId] ? @" (me)" : @"")],
                                //[message[@"date"] description],
                                [message[@"isPublic"] boolValue] ? @"Public" : @"Private"
                                ];
    
    [[[UIAlertView alloc] initWithTitle:@"Message details" message:messageDetails delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - IBActions

- (IBAction)sendTap:(UIButton *)sender {
    [self processMessage];
}

- (IBAction)dismissKeyboardTap:(UIButton *)sender {
    [self hideKeyboardIfNeeded];
}

- (IBAction)peersTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:sender.titleLabel.text  message:[self.peers description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UITextField delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.nicknameTextField]) {
        [self updateNickname];
    }
    else if ([textField isEqual:self.messageTextField]) {
        [self processMessage];
    }
    
    [self hideKeyboardIfNeeded];
    
    return YES;
}

#pragma mark - Utils

-(void)processMessage {
    
    if (self.isPublicSwitch.isOn && self.messageTypeSegmentControl.selectedSegmentIndex == 2) {
        [[[UIAlertView alloc] initWithTitle:@"Binary data is private." message:@"\nTo send your message as binary data, uncheck the \"Public\" UISwitch." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self hideKeyboardIfNeeded];
    }
    else if (self.messageTextField.text.length > 0) {
        
        NSString *message = self.messageTextField.text;
        
        
        if (!self.isPublicSwitch.isOn)
        { // private message
            
            if (self.peers.count) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choose a private recipient."
                                            message:@"\nYou're about to send a private message\nWho do you want to send it to ?"
                                   cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil]
                                   otherButtonItems:nil
                  ];
                for (NSString *peerDicKey in self.peers.allKeys) {
                    [alert addButtonItem:
                     [RIButtonItem itemWithLabel:self.peers[peerDicKey]
                                          action:^{
                                              [self sendMessage:message forPeerId:peerDicKey];
                                          }]
                     ];
                }
                [alert show];
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"No peer connected."  message:@"\nYou can't define a private recipient since there is no peer connected." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }

            
        }
        else
        { // public message
            [self sendMessage:message forPeerId:nil];
        }
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Empty message" message:@"\nType the message to be sent." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
}

-(void)sendMessage:(NSString *)message forPeerId:(NSString *)peerId { // nil peerId means public message
    BOOL showSentMessage = YES;
    switch (self.messageTypeSegmentControl.selectedSegmentIndex) {
        case 0:
            [self.skylinkConnection sendDCMessage:message peerId:peerId];
            break;
            
        case 1:
            [self.skylinkConnection sendCustomMessage:message peerId:peerId]; // message could also be custom structure like: ...sendCustomMessage:@{@"message" : message}...
            break;
            
        case 2:
            @try {
                if (peerId) [self.skylinkConnection sendBinaryData:[message dataUsingEncoding:NSUTF8StringEncoding] peerId:peerId];
            }
            @catch (NSException *e) {
                NSString *message = [NSString stringWithFormat:@"\n%@", e];
                if ([e.reason isEqualToString:@"Sending binary data in a MCU connection is not supported"]) message = [message stringByAppendingString:@"\n\nSkylink Media Relay can be enabled/disabled in Key configuration on the developer portal: http://developer.temasys.com.sg/"];
                [[[UIAlertView alloc] initWithTitle:@"Exeption when sending binary data"  message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                showSentMessage = NO;
            }
            break;
            
        default:
            break;
    }
    
    if (showSentMessage) {
        self.messageTextField.text = @"";
        [self.messages insertObject:@{@"message" : message,
                                      @"isPublic" :[NSNumber numberWithBool:(!peerId)],
                                      @"peerId" : self.skylinkConnection.myPeerId}
                            atIndex:0];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    else {
        [self hideKeyboardIfNeeded];
    }
}

-(void)updateNickname {
    if (self.nicknameTextField.text.length > 0) {
        [self.skylinkConnection sendUserInfo:@{@"nickname" : self.nicknameTextField.text}];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Empty nickname" message:@"\nType the nickname to set." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)updatePeersButtonTitle {
    NSUInteger peersCount = self.peers.count;
    if (peersCount == 0) {
        [self.peersButton setTitle:@"No peer" forState:UIControlStateNormal];
    }
    else {
        [self.peersButton setTitle:[NSString stringWithFormat:@"%lu peer%@", (unsigned long)peersCount, (peersCount > 1) ? @"s" : @""] forState:UIControlStateNormal];
    }
}

-(void)hideKeyboardIfNeeded {
    [self.messageTextField resignFirstResponder];
    [self.nicknameTextField resignFirstResponder];
}


@end

