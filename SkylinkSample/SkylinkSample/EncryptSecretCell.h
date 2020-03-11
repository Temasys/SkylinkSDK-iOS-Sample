//
//  EncryptSecretCell.h
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *CELL_IDENTIFIER_ENCRYPT_SECRET = @"EncryptSecretCell";

@interface EncryptSecretCell : UITableViewCell<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *secretIdField;
@property (weak, nonatomic) IBOutlet UITextField *secretField;
- (void)setupCell:(NSString *)secretId secret:(NSString *)secret;
@end

NS_ASSUME_NONNULL_END
