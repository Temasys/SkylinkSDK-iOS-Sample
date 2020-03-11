//
//  EncryptSecretCell.m
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import "EncryptSecretCell.h"
#import "Constant.h"
@implementation EncryptSecretCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)setupCell:(NSString *)secretId secret:(NSString *)secret {
    _secretIdField.text = secretId;
    _secretField.text = secret;
}
- (void)textFieldDidChangeSelection:(UITextField *)textField{
    if (textField == _secretField){
        [SAConstants.shared.ENCRYPTION_SECRETS setObject:textField.text  forKey:_secretIdField.text];
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == _secretField) {
        NSString *_updateString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        SAConstants.shared.ENCRYPTION_SECRETS[_secretIdField.text] = _updateString;
    }
    return YES;
}
@end
