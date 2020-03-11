//
//  SettingCell.m
//  SkylinkSample
//
//  Created by Temasys on 5/9/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

#import "SettingCell.h"
#import "Constant.h"

//static NSString *CELL_IDENTIFIER = @"SettingCell";
//static SAConstants *shared = nil;

@interface SettingCell()
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UITextField *valueField;
@end

@implementation SettingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)setupCellWithKey:(NSString *)key value:(NSString *)value
{
    self.keyLabel.text = key;
    self.valueField.text = value;
}

- (void)textChanged
{
    if (!self.valueField.text || [self.valueField.text containsString:@" "]) {
        MyLog(@"Room name not valid");
    } else {
        if ([self.keyLabel.text isEqualToString:@"App Key"]) APP_KEY = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"App Secret"]) APP_SECRET = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"1-1 video call"]) ROOM_ONE_TO_ONE_VIDEO = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"Multi video call"]) ROOM_MULTI_VIDEO = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"Audio call"]) ROOM_AUDIO = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"Messages"]) ROOM_MESSAGES = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"File transfer"]) ROOM_FILE_TRANSFER = self.valueField.text;
        else if ([self.keyLabel.text isEqualToString:@"Data transfer"]) ROOM_DATA_TRANSFER = self.valueField.text;
    }
}
@end
