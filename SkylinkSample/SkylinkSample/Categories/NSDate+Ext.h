//
//  NSDate+Ext.h
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate(Ext)
- (NSString*)skylinkDateString;
+ (NSDate*)skylinkDateFromString:(NSString*)string;

- (long long)toTimeStamp;
+ (NSDate *)dateFromTimeStamp:(long long)timeStamp;
@end

NS_ASSUME_NONNULL_END
