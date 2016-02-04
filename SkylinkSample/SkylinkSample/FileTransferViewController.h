//
//  FileTransferViewController.h
//  Skylink_Examples
//
//  Created by Romain Pellen on 18/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKYLINK/SKYLINK.h>
#import <MediaPlayer/MediaPlayer.h>

@interface FileTransferViewController : UIViewController <MPMediaPickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionFileTransferDelegate, SKYLINKConnectionRemotePeerDelegate>

@property (strong, nonatomic) NSString *skylinkApiKey;
@property (strong, nonatomic) NSString *skylinkApiSecret;

@end
