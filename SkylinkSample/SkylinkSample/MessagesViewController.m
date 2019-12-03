//
//  MessagesViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 04/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "MessagesViewController.h"
#import "Constant.h"

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_MESSAGES"]


@interface MessagesViewController ()<SKYLINKConnectionMessagesDelegate>
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
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *peers;

@end


@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Messages";
    self.messages = [[NSMutableArray alloc] initWithArray:@[]];
    self.peers = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    [self updatePeersButtonTitle];
    
    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoSendConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_NO_AUDIO_NO_VIDEO];
    config.hasP2PMessaging = YES;
    // Creating SKYLINKConnection
    _skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    _skylinkConnection.lifeCycleDelegate = self;
    _skylinkConnection.messagesDelegate = self;
    _skylinkConnection.remotePeerDelegate = self;
    // Connecting to a room
    [_skylinkConnection connectToRoomWithAppKey:APP_KEY secret:APP_SECRET roomName:ROOM_MESSAGES userData:USER_NAME callback:nil];
}

#pragma mark - SKYLINKConnectionLifeCycleDelegate
- (void)connectionDidConnectToRoomSuccessful:(SKYLINKConnection *)connection
{
    MyLog(@"Inside %s", __FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.messageTextField.enabled = YES;
        self.messageTextField.hidden = NO;
        self.nicknameTextField.enabled = YES;
        self.nicknameTextField.hidden = NO;
        self.sendButton.enabled = YES;
        self.sendButton.hidden = NO;
        [self.messageTextField becomeFirstResponder];
        [self.activityIndicator stopAnimating];
    });
}

- (void)connection:(SKYLINKConnection *)connection didConnectToRoomFailed:(NSString *)errorMessage
{
    [UIAlertController showAlertWithAutoDisappearTitle:@"Connection failed" message:errorMessage duration:3 onViewController:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)connection:(SKYLINKConnection *)connection didDisconnectFromRoomWithSkylinkEvent:(NSDictionary *)skylinkEvent contextDescription:(NSString *)contextDescription
{
//    [UIAlertController showAlertWithAutoDisappearTitle:@"Disconnected" message:contextDescription duration:3 onViewController:self];
//    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - SKYLINKConnectionMessagesDelegate
- (void)connection:(SKYLINKConnection *)connection didReceiveServerMessage:(id)message isPublic:(BOOL)isPublic remotePeerId:(NSString *)remotePeerId
{
    [self.messages insertObject:@{@"message" : message, @"isPublic" : @(isPublic), @"peerId" : remotePeerId, @"type" : @"signaling server"} atIndex:0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveP2PMessage:(id)message isPublic:(BOOL)isPublic remotePeerId:(NSString *)remotePeerId
{
    [self.messages insertObject:@{@"message" : message, @"isPublic" : @(isPublic), @"peerId" : remotePeerId, @"type" : @"P2P"} atIndex:0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - SKYLINKConnectionRemotePeerDelegate
- (void)connection:(SKYLINKConnection *)connection didConnectWithRemotePeer:(NSString *)remotePeerId userInfo:(id)userInfo hasDataChannel:(BOOL)hasDataChannel
{
    NSString *displayNickname = (userInfo && [userInfo isKindOfClass:[NSDictionary class]] && userInfo[@"nickname"]) ? userInfo[@"nickname"] : [NSString stringWithFormat:@"ID: %@", remotePeerId];
    [self.peers addEntriesFromDictionary:@{remotePeerId:displayNickname}];
    [self updatePeersButtonTitle];
    [self.tableView reloadData];
    [self.activityIndicator stopAnimating];
}

- (void)connection:(SKYLINKConnection *)connection didReceiveRemotePeerLeaveRoom:(NSString *)remotePeerId userInfo:(id)userInfo skylinkInfo:(NSDictionary *)skylinkInfo
{
    MyLog(@"Peer with ID %@ left with skylinkInfo: %@", remotePeerId, skylinkInfo);
    [self.peers removeObjectForKey:remotePeerId];
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
    if ([message[@"peerId"] isEqualToString:_skylinkConnection.localPeerId]) {
        cell.detailTextLabel.text = [message[@"isPublic"] boolValue] ? @"Sent to all" : @"Sent privately";
        cell.backgroundColor = [UIColor colorWithRed:0.71 green:1 blue:0.5 alpha:1];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"From %@ via %@ • %@", (self.peers[message[@"peerId"]]) ? self.peers[message[@"peerId"]] : message[@"peerId"], message[@"type"], [message[@"isPublic"] boolValue] ? @"Public" : @"Private"];
        cell.backgroundColor = [UIColor whiteColor];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *message = [self.messages objectAtIndex:indexPath.row];
    NSString *messageDetails = [NSString stringWithFormat:@"Message:\n%@\n\nFrom :\n%@\n\n%@", message[@"message"], [message[@"peerId"] stringByAppendingString:([message[@"peerId"] isEqualToString:_skylinkConnection.localPeerId] ? @" (me)" : @"")], [message[@"isPublic"] boolValue] ? @"Public" : @"Private"];
    
    [UIAlertController showAlertWithAutoDisappearTitle:@"Message details" message:messageDetails duration:3 onViewController:self];
}

#pragma mark - IBActions

- (IBAction)sendTap:(UIButton *)sender {
    [self processMessage];
}

- (IBAction)dismissKeyboardTap:(UIButton *)sender {
    [self hideKeyboardIfNeeded];
}

- (IBAction)peersTap:(UIButton *)sender {
    [UIAlertController showAlertWithAutoDisappearTitle:sender.titleLabel.text message:[self.peers description] duration:3 onViewController:self];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.nicknameTextField]) [self updateNickname];
    else if ([textField isEqual:self.messageTextField]) [self processMessage];
    [self hideKeyboardIfNeeded];
    return YES;
}

#pragma mark - Utils
-(void)alert:(NSString *)title message:(NSString*)message{
    showAlert(title, message);
    [self sendMessage:message forPeerId:[title stringByReplacingOccurrencesOfString:@"ID: " withString:@""]];
}
- (void)processMessage {
    if (self.messageTextField.text.length > 0) {
        NSString *message = self.messageTextField.text;
        if (!self.isPublicSwitch.isOn){
            if (_peers.count != 0) {
                UIAlertController *_alert = [UIAlertController alertControllerWithTitle:@"Choose a private recipient." message:@"\nYou're about to send a private message\nWho do you want to send it to ?" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *_cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
                __weak __typeof(self)weakSelf = self;
                for (NSString *peerDicKey in _peers.allKeys) {
                    UIAlertAction *_peerAction = [UIAlertAction actionWithTitle:_peers[peerDicKey] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [weakSelf alert:self->_peers[peerDicKey] message:message];
                    }];
                    [_alert addAction:_peerAction];
                }
                [_alert addAction:_cancelAction];
                [self presentViewController:_alert animated:YES completion:nil];
            } else {
                showAlertAutoDismiss(@"No peer connected.", @"\nYou can't define a private recipient since there is no peer connected.", 2, self);
            }
        }else{
            [self sendMessage:message forPeerId:nil];
        }
    } else [UIAlertController showAlertWithAutoDisappearTitle:@"Empty message" message:@"\nType the message to be sent." duration:3 onViewController:self];
}

- (void)sendMessage:(NSString *)message forPeerId:(NSString *)peerId { // nil peerId means public message
    BOOL showSentMessage = YES;
    if (self.messageTypeSegmentControl.selectedSegmentIndex == 0) {
        [_skylinkConnection sendP2PMessage:message toRemotePeerId:peerId callback:^(NSError * _Nullable error) {
            if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
        }];
    } else if (self.messageTypeSegmentControl.selectedSegmentIndex == 1) {
        [_skylinkConnection sendServerMessage:message toRemotePeerId:peerId callback:^(NSError * _Nullable error) {
            if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
        }]; // message could also be custom structure like: ...sendCustomMessage:@{@"message" : message}...
    }
    
    if (showSentMessage) {
        self.messageTextField.text = @"";
        [self.messages insertObject:@{@"message" : message, @"isPublic" :[NSNumber numberWithBool:(!peerId)], @"peerId" : _skylinkConnection.localPeerId} atIndex:0];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else [self hideKeyboardIfNeeded];
}

- (void)updateNickname {
    if (self.nicknameTextField.text.length > 0) [_skylinkConnection sendLocalUserData:@{@"nickname" : self.nicknameTextField.text} callback:^(NSError * _Nullable error) {
        if (error) [UIAlertController showAlertWithAutoDisappearTitle:@"Error" message:error.localizedDescription duration:3 onViewController:self];
    }];
    else [UIAlertController showAlertWithAutoDisappearTitle:@"Empty nickname" message:@"\nType the nickname to set." duration:3 onViewController:self];
}

- (void)updatePeersButtonTitle {
    NSUInteger peersCount = self.peers.count;
    if (peersCount == 0) [self.peersButton setTitle:@"No peer" forState:UIControlStateNormal];
    else [self.peersButton setTitle:[NSString stringWithFormat:@"%lu peer%@", (unsigned long)peersCount, (peersCount > 1) ? @"s" : @""] forState:UIControlStateNormal];
}

- (void)hideKeyboardIfNeeded {
    [self.messageTextField resignFirstResponder];
    [self.nicknameTextField resignFirstResponder];
}


@end

