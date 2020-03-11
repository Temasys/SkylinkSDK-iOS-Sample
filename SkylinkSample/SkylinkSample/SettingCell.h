//
//  SettingCell.h
//  SkylinkSample
//
//  Created by Temasys on 5/9/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

//extern NSString * const CELL_IDENTIFIER;
static NSString *CELL_IDENTIFIER = @"SettingCell";

@interface SettingCell : UITableViewCell
- (void)setupCellWithKey:(NSString *)key value:(NSString *)value;
@end

//NS_ASSUME_NONNULL_END
