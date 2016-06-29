//
//  ViewController.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 11/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "HomeViewController.h"





// ====== SET YOUR KEY / SECRET HERE TO HAVE IT BY DEFAULT. ======
// If you don't have any key/secret, enroll at developer.temasys.com.sg
#define SKYLINK_APP_KEY @""
#define SKYLINK_SECRET  @""

// remove the folowing warning once you filled the above with your API key/secret
#warning directive You need to set your Skylink API key & secret






// Just the NSUserDefaults keys.
#define USERDEFAULTS_KEY_SKYLINK_APP_KEY @"SKYLINK_APP_KEY"
#define USERDEFAULTS_KEY_SKYLINK_SECRET  @"SKYLINK_SECRET"


@interface HomeViewController () // This View controller only passes your API Key and Secret to the sample view controllers. No need to explore this VC's code to understand Skylink SDK.

@property (weak, nonatomic) IBOutlet UITextField *keyTextField;
@property (weak, nonatomic) IBOutlet UITextField *secretTextField;

@end


@implementation HomeViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (SKYLINK_APP_KEY.length) self.keyTextField.text = SKYLINK_APP_KEY;
    if (SKYLINK_SECRET.length) self.secretTextField.text = SKYLINK_SECRET;
    
    // Priority is given to code defined Key/Secret
    if (!(SKYLINK_APP_KEY.length) && !(SKYLINK_SECRET.length)) {
        NSString *defaultKey = [[NSUserDefaults standardUserDefaults] objectForKey:USERDEFAULTS_KEY_SKYLINK_APP_KEY];
        NSString *defaultSecret = [[NSUserDefaults standardUserDefaults] objectForKey:USERDEFAULTS_KEY_SKYLINK_SECRET];
        if (defaultKey && defaultKey.length) self.keyTextField.text = defaultKey;
        if (defaultSecret && defaultSecret.length) self.secretTextField.text = defaultSecret;
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerform = (self.keyTextField.text.length == 36 && self.secretTextField.text.length == 13);
    if (!shouldPerform) {
        [[[UIAlertView alloc] initWithTitle:@"Wrong Key / Secret" message:@"\nYou haven't correctly set your \nSkylink API Key (36 characters) or Secret (13 characters)\n\nIf you don't have access to the API yet, enroll at \ndeveloper.temasys.com.sg/register" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:self.keyTextField.text forKey:USERDEFAULTS_KEY_SKYLINK_APP_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:self.secretTextField.text forKey:USERDEFAULTS_KEY_SKYLINK_SECRET];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return shouldPerform;
}

#pragma clang diagnostic ignored "-Wundeclared-selector"
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController respondsToSelector:@selector(setSkylinkApiKey:)] && [segue.destinationViewController respondsToSelector:@selector(setSkylinkApiSecret:)]) {
        [segue.destinationViewController performSelector:@selector(setSkylinkApiKey:) withObject:self.keyTextField.text];
        [segue.destinationViewController performSelector:@selector(setSkylinkApiSecret:) withObject:self.secretTextField.text];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - IBActions (info boxes)
// Information alerts only

- (IBAction)homeInfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"HomeViewController" message:@"\nSet you Skylink API Key and secret in the appropriate text field or modify HomeViewController's code to have it by default.\nIf you don't have your Key/Secret, enroll at developer.temasys.com.sg/register\n\nIn all view controllers, you can tap the info button in the upper right corner to get the current room name, your current local ID, the current API key and the current SDK version. Refer to the documentation for more infos on how to use it.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)videoCallVCinfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"VideoCallViewController" message:@"\nOne to one video call sample\n\nThe first 2 people to enter the room will be able to have a video call. The bottom bar contains buttons to refresh the peer connection, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)multiVideoCallVCinfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"MultiViewController" message:@"\nThe first 4 people to enter the room will be able to have a multi party video call (as long as the room isn't locked). The bottom bar contains buttons to change the aspect of the peer video views, lock/unlock the room, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)audioCallVCinfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"AudioCallViewController" message:@"\nEnter the room to make an audio call with the other peers inside the same room. Tap the button on top to mute/unmute your microphone.\n\nRefer to the view controller's code and to the documentation for more infos.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)messagesVCinfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"MessagesViewController" message:@"\nEnter the room to chat with the peers in the same room. The first text field allows you to edit your nickname, the yellow button indicates the number of peers in the room: tap it to display theirs ID and nickname if available, tap the icon to hide the keyboard if needed. There is also a button to select the type of messages you want to test (P2P, signeling server or binary data), and another one to choose if you want to send your messages to all the peers in the room (public) or privatly. If not public, you will be ask what peer you want to send your private message to when tapping the send button. To send a message, enter it in the second text field and tap the send button. The messages you sent appear in green.\n\nRefer to the view controller's code and to the documentation for more infos.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)fileTransferVCinfoTap:(UIButton *)sender {
    [[[UIAlertView alloc] initWithTitle:@"FileTransferViewController" message:@"\nEnter the room to send file to the ppers in the same room. To send a file to all the peers, tap the main button, to send it to a particular peer, tap the peer in the list. In both cases you will be asked the king of media you want to send and to pick it if needed.\nBehaviour will be slightly different with MCU enabled.\n\nRefer to the view controller's code and to the documentation for more infos.\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


@end


