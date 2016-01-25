//
//  TEMFilePickerController.h
//  TEM
//
//  Created by macbookpro on 04/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TEMFilePickerController;

@protocol TEMFilePickerControllerDelegate <NSObject>

- (void)filePicker:(TEMFilePickerController*)filePicker didPickFile:(NSURL*)fileURL;
- (void)filePickerDidCancel:(TEMFilePickerController*)filePicker;

@end

@interface TEMFilePickerController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id<TEMFilePickerControllerDelegate> delegate;

@end
