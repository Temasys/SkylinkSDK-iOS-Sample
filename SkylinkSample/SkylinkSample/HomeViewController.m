//
//  ViewController.m
//  Skylink_Examples
//
//  Created by Temasys on 11/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "HomeViewController.h"
#import "Constant.h"

/// ====== SET YOUR KEY / SECRET HERE TO HAVE IT BY DEFAULT. ======
#define SKYLINK_APP_KEY APP_KEY
#define SKYLINK_SECRET  APP_SECRET
/// ===============================================================




// Just the NSUserDefaults keys.
#define USERDEFAULTS_KEY_SKYLINK_APP_KEY @"SKYLINK_APP_KEY"
#define USERDEFAULTS_KEY_SKYLINK_SECRET  @"SKYLINK_SECRET"



@interface HomeViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *roomNameTxt;
@end


@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _roomNameTxt.text = ROOM_NAME;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerform = true;// = (self.keyTextField.text.length == 36 && self.secretTextField.text.length == 13);
    if (!shouldPerform) {
        [UIAlertController showAlertWithAutoDisappearTitle:@"Wrong Key / Secret" message:@"\nYou haven't correctly set your \nSkylink API Key (36 characters) or Secret (13 characters)\n\nIf you don't have access to the API yet, enroll at \nconsole.temasys.io" duration:3 onViewController:self];
    } else {
//        [[NSUserDefaults standardUserDefaults] setObject:self.keyTextField.text forKey:USERDEFAULTS_KEY_SKYLINK_APP_KEY];
//        [[NSUserDefaults standardUserDefaults] setObject:self.secretTextField.text forKey:USERDEFAULTS_KEY_SKYLINK_SECRET];
//        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return shouldPerform;
}

#pragma clang diagnostic ignored "-Wundeclared-selector"
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.destinationViewController respondsToSelector:@selector(setSkylinkApiKey:)] && [segue.destinationViewController respondsToSelector:@selector(setSkylinkApiSecret:)]) {
//        [segue.destinationViewController performSelector:@selector(setSkylinkApiKey:) withObject:self.keyTextField.text];
//        [segue.destinationViewController performSelector:@selector(setSkylinkApiSecret:) withObject:self.secretTextField.text];
//    }
}

#pragma mark - IBActions (info boxes)
// Information alerts only
- (IBAction)vcInfoClicked:(UIButton *)sender{
    NSArray *alertTitles = @[@"Audio", @"One to one Media", @"Chat", @"Mutiparty", @"File Transfer", @"Data Streaming"];
    NSArray *alertMessages = @[@"\nEnter the room to make an audio call with the other peers inside the same room. Tap the button on top to mute/unmute your microphone.\n\nRefer to the view controller's code and to the documentation for more infos.",
    @"\nOne to one video call sample\n\nThe first 2 people to enter the room will be able to have a video call. The bottom bar contains buttons to refresh the peer connection, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n",
    @"\nEnter the room to chat with the peers in the same room. The first text field allows you to edit your nickname, the yellow button indicates the number of peers in the room: tap it to display theirs ID and nickname if available, tap the icon to hide the keyboard if needed. There is also a button to select the type of messages you want to test (P2P, signeling server or binary data), and another one to choose if you want to send your messages to all the peers in the room (public) or privatly. If not public, you will be ask what peer you want to send your private message to when tapping the send button. To send a message, enter it in the second text field and tap the send button. The messages you sent appear in green.\n\nRefer to the view controller's code and to the documentation for more infos.\n",
    @"\nThe first 4 people to enter the room will be able to have a multi party video call (as long as the room isn't locked). The bottom bar contains buttons to change the aspect of the peer video views, lock/unlock the room, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n",
    @"\nEnter the room to send file to the peers in the same room. To send a file to all the peers, tap the main button, to send it to a particular peer, tap the peer in the list. In both cases you will be asked the king of media you want to send and to pick it if needed.\nBehaviour will be slightly different with MCU enabled.\n\nRefer to the view controller's code and to the documentation for more infos.\n",
    @"\nEnter the room to send data to the peers in the same room. To send a file to all the peers, tap the main button, to send it to a particular peer, tap the peer in the list. In both cases you will be asked the king of media you want to send and to pick it if needed.\nBehaviour will be slightly different with MCU enabled.\n\nRefer to the view controller's code and to the documentation for more infos.\n"];
    showAlertTouchDismiss(alertTitles[sender.tag - 10], alertMessages[sender.tag - 10]);
}
- (IBAction)homeInfoTap:(UIButton *)sender {
    [UIAlertController showAlertWithAutoDisappearTitle:@"HomeViewController" message:@"\nSet you Skylink API Key and secret in the appropriate text field or modify HomeViewController's code to have it by default.\nIf you don't have your Key/Secret, enroll at console.temasys.io\n\nIn all view controllers, you can tap the info button in the upper right corner to get the current room name, your current local ID, the current API key and the current SDK version. Refer to the documentation for more infos on how to use it.\n" duration:3 onViewController:self];
}

#pragma mark - TextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
- (void)textFieldDidChangeSelection:(UITextField *)textField{
    if (textField == self.roomNameTxt) {
        ROOM_NAME = textField.text;
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.roomNameTxt) {
        NSString *updateString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        ROOM_NAME = updateString;
    }
    return YES;
}
- (BOOL)textFieldShouldClear:(UITextField *)textField{
    ROOM_NAME = nil;
    return YES;
}
@end


