//
//  MessagesViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 04/01/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "MessagesViewController.h"
#import "Constant.h"
#import "SAMessage.h"

//#define ROOM_NAME [[NSUserDefaults standardUserDefaults] objectForKey:@"ROOMNAME_MESSAGES"]


@interface MessagesViewController ()<SKYLINKConnectionMessagesDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *isPublicSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *messageTypeSegmentControl;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UIButton *peersButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *encryptKeyTextField;
@property (weak, nonatomic) IBOutlet UIView *pickerViewContainer;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UISwitch *persistSwitch;

// Properties
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *peers;

@end


@implementation MessagesViewController{
    NSArray *_encryptSecretIds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Messages";
    self.messages = [NSMutableArray new];
    self.peers = [NSMutableDictionary new];
    [self updatePeersButtonTitle];
    [self loadStoredMessage];
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
    _skylinkConnection.encryptSecrets = SAConstants.shared.ENCRYPTION_SECRETS;
    // Connecting to a room
    [self joinRoom];
    _encryptSecretIds = [@[@"No Key"] arrayByAddingObjectsFromArray:[SAConstants.shared.ENCRYPTION_SECRETS.allKeys sortedArrayUsingSelector:@selector(compare:)]];
    _encryptKeyTextField.text = _encryptSecretIds.firstObject;
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
- (void)connection:(SKYLINKConnection *)connection didReceiveServerMessage:(id)message isPublic:(BOOL)isPublic timeStamp:(long long)timeStamp remotePeerId:(NSString *)remotePeerId{
    NSLog(@"SIG message");
    if ([message isKindOfClass:[NSString class]]) {
        SAMessage *receivedMsg = [[SAMessage alloc] initWithData:message timeStamp:timeStamp sender:[self getUserNameFrom:remotePeerId] target:(isPublic ? nil : _skylinkConnection.localPeerId) type:SAMessageTypeP2P];
        [_messages addObject:receivedMsg];
        [_tableView reloadData];
    }
}
- (void)connection:(SKYLINKConnection *)connection didReceiveP2PMessage:(id)message isPublic:(BOOL)isPublic timeStamp:(long long)timeStamp remotePeerId:(NSString *)remotePeerId{
    NSLog(@"P2P message");
    if ([message isKindOfClass:[NSString class]]) {
        SAMessage *receivedMsg = [[SAMessage alloc] initWithData:message timeStamp:timeStamp sender:[self getUserNameFrom:remotePeerId] target:(isPublic ? nil : _skylinkConnection.localPeerId) type:SAMessageTypeP2P];
        [_messages addObject:receivedMsg];
        [_tableView reloadData];
    }
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
    
    SAMessage *message = [_messages objectAtIndex: _messages.count - indexPath.row - 1];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@~~~%@", [message timeStampString], message.data];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"From %@ via %@ • %@", message.sender, message.typeToString, [message isPublicString]];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SAMessage *message = [self.messages objectAtIndex:_messages.count - indexPath.row - 1];
    NSString *messageDetails = [NSString stringWithFormat:@"Message:\n%@\n\nFrom :\n%@\n\n%@", message.data, ([message.sender isEqualToString:USER_NAME] ? @"me" : message.sender), [message isPublicString]];
    showAlert(@"Message Detail", messageDetails);
}

#pragma mark - IBActions

- (IBAction)sendTap:(UIButton *)sender {
    _skylinkConnection.messagePersist = _persistSwitch.isOn;
    NSString *message = _messageTextField.text;
    if (_peers.count<=0) {
        showAlert(@"No peer connected", @"\nYou can't define a private recipient since there is no peer connected.");
        return;
    }
    
    if (![message isNotEmpty]) {
        showAlert(@"Empty Message", @"\nType the message to be sent.");
        return;
    }
    
    if (_isPublicSwitch.isOn) {
        //send public
        [self sendMessage:message forPeerId:nil];
    }else{
        //send private
        UIAlertController *_alert = [UIAlertController alertControllerWithTitle:@"Choose a private recipient." message:@"\nYou're about to send a private message\nWho do you want to send it to ?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *_cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
        __weak __typeof(self)weakSelf = self;
        for (NSString *peerDicKey in _peers.allKeys) {
            UIAlertAction *_peerAction = [UIAlertAction actionWithTitle:_peers[peerDicKey] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf sendMessage:message forPeerId:peerDicKey];
//                [weakSelf alert:self->_peers[peerDicKey] message:message];
            }];
            [_alert addAction:_peerAction];
        }
        [_alert addAction:_cancelAction];
        [self presentViewController:_alert animated:YES completion:nil];
    }
}

- (IBAction)dismissKeyboardTap:(UIButton *)sender {
    [self hideKeyboardIfNeeded];
}

- (IBAction)peersTap:(UIButton *)sender {
    [UIAlertController showAlertWithAutoDisappearTitle:sender.titleLabel.text message:[self.peers description] duration:3 onViewController:self];
}
- (IBAction)doneEncryptSecret:(UIButton *)sender{
    [self.pickerViewContainer setHidden:YES];
}


#pragma mark - Utils
-(void)alert:(NSString *)title message:(NSString*)message{
    showAlert(title, message);
    [self sendMessage:message forPeerId:[title stringByReplacingOccurrencesOfString:@"ID: " withString:@""]];
}

- (void)sendMessage:(NSString *)message forPeerId:(NSString *)peerId { // nil peerId means public message
    void (^processResponse)(NSError *, SAMessageType) = ^(NSError *error, SAMessageType type){
        if (error) {
            showAlert([NSString stringWithFormat:@"ERROR: %ld", (long)error.code], error.localizedDescription);
        }else{
            SAMessage *msg = [[SAMessage alloc] initWithData:message timeStamp:[[NSDate date] toTimeStamp] sender:USER_NAME target:peerId type:type];
            [self->_messages addObject:msg];
            self.messageTextField.text = @"";
            [self.tableView reloadData];
            showAlert(message, peerId ? peerId : @"All");
        }
    };
    if (_messageTypeSegmentControl.selectedSegmentIndex) {
        [_skylinkConnection sendServerMessage:message toRemotePeerId:peerId callback:^(NSError * _Nullable error) {
            processResponse(error, SAMessageTypeSignaling);
        }];
    }else{
        [_skylinkConnection sendP2PMessage:message toRemotePeerId:peerId callback:^(NSError * _Nullable error) {
            processResponse(error, SAMessageTypeP2P);
        }];
    }
    
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
    [self.encryptKeyTextField resignFirstResponder];
}
- (void)loadStoredMessage{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_skylinkConnection getStoredMessages:^(NSArray * _Nullable storedMessages, NSDictionary * _Nullable errors) {
            if (!self.view.window) {
                return;
            }
            if (errors) {
                showAlert(@"Error map", errors.description);
            }
            for (NSDictionary *item in storedMessages) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    SAMessage *message = [[SAMessage alloc] initWithData:item[@"data"] timeStamp:[item[@"timeStamp"] longLongValue] sender:[self getUserNameFrom:item[@"peerId"]] target:nil type:SAMessageTypeSignaling];
                    [self.messages addObject:message];
                }
            }
            [self.tableView reloadData];
        }];
    });
}
- (NSString *)getUserNameFrom:(NSString *)peerId{
    NSDictionary *userInfo = [_skylinkConnection getUserInfo:peerId];
    if (userInfo) {
        return userInfo[@"userData"];
    }
    return peerId;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.nicknameTextField]) [self updateNickname];
    [self hideKeyboardIfNeeded];
    return YES;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == self.encryptKeyTextField) {
        [self hideKeyboardIfNeeded];
        [_pickerViewContainer setHidden:NO];
        return NO;
    }
    return YES;
}
#pragma mark - PICKER VIEW
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return _encryptSecretIds.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return _encryptSecretIds[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSString *selectedEncryptSecret = (row == 0) ? nil : _encryptSecretIds[row];
    _skylinkConnection.selectedSecretId = selectedEncryptSecret;
    _encryptKeyTextField.text = _encryptSecretIds[row];
}
@end

