//
//  TEMPresenceTableViewController.h
//  TEM
//
//  Created by macbookpro on 02/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

#import "TEMFilePickerController.h"

@interface TEMPresenceTableViewController : UITableViewController <MPMediaPickerControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TEMFilePickerControllerDelegate>

- (void)addChatMessage:(NSString*)message nick:(NSString*)nick peerId:(NSString*)peerId isPublic:(BOOL)isPublic;
- (void)addParticipant:(NSString*)nick peerId:(NSString*)peerId;
- (void)deleteParticipant:(NSString*)peerId;
- (void)highlightPanelButton;
- (NSString*)updateParticipant:(NSString*)nick peerId:(NSString*)peerId;

@end
