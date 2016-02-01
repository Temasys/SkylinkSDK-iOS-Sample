//
//  TEMJoinViewController.m
//  TEM
//
//  Created by macbookpro on 01/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "TEMJoinViewController.h"

#import "TEMAppDelegate.h"
#import "TEMCommon.h"
#import "TEMRoomViewController.h"

#define SIBLING_PADDING 8

@interface TEMJoinViewController () {
    CGRect contentViewFrame;
}

@property (weak, nonatomic) IBOutlet UITextField *displayNameField;
@property (weak, nonatomic) IBOutlet UITextField *roomNameField;

@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation TEMJoinViewController 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Set the default room name (optional)
    // Populate this field for quicker testing.
    self.roomNameField.text = @"";
    
    NSLog(@"Using Skylink SDK for iOS, version: %@.", [SKYLINKConnection getSkylinkVersion]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    // Disable rotation for iOS 8.0+
    return !(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"));
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.displayNameField) {
        [self.roomNameField becomeFirstResponder];
    } else {
        [self joinButtonTapped:nil];
    }
    return YES;
}

#pragma mark - NSNotification

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardFrame;
    [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:((TEMAppDelegate*)[UIApplication sharedApplication].delegate).window];
    
    contentViewFrame = self.contentView.frame;
    
    CGFloat deltaY = keyboardFrame.origin.y - (CGRectGetMaxY(contentViewFrame) + SIBLING_PADDING);
    if (deltaY < 0) {
        [UIView animateWithDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y + deltaY, self.contentView.frame.size.width, self.contentView.frame.size.height);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [UIView animateWithDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        self.contentView.frame = contentViewFrame;
    }];
}

#pragma mark - IBAction

- (IBAction)contentViewTapped:(id)sender {
    [self.displayNameField resignFirstResponder];
    [self.roomNameField resignFirstResponder];
}

- (IBAction)joinButtonTapped:(id)sender {
    NSString *displayName = [self.displayNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *roomName = [self.roomNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (displayName.length <= 0) {
        // Test Crashlytics by uncommenting following.
        // [[Crashlytics sharedInstance] crash];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Missing Value!" message:@"Please enter display name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [self.displayNameField becomeFirstResponder];
        return;
    } else if (roomName.length <= 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Missing Value!" message:@"Please enter room name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [self.roomNameField becomeFirstResponder];
        return;
    }
    
    [self.displayNameField resignFirstResponder];
    [self.roomNameField resignFirstResponder];
    TEMRoomViewController *roomViewController = [[TEMRoomViewController alloc] initWithRoomName:roomName displayName:displayName];
    [self presentViewController:roomViewController animated:YES completion:nil];
    ((TEMAppDelegate*)[UIApplication sharedApplication].delegate).roomViewController = roomViewController;
}

@end
