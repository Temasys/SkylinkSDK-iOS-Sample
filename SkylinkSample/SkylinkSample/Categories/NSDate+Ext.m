//
//  NSDate+Ext.m
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import "NSDate+Ext.h"

@implementation NSDate(Ext)
- (long long)toTimeStamp{
    return (long long) (self.timeIntervalSince1970 * 1000);
}
+ (NSDate *)dateFromTimeStamp:(long long)timeStamp{
    return [NSDate dateWithTimeIntervalSince1970:(double)timeStamp];
}

- (NSString *)skylinkDateString{
    return [NSDate stringFromDate:self format:@"yyyy-MM-dd'T'HH:mm:ss.0'Z'"];
}
+ (NSDate*)skylinkDateFromString:(NSString*)string{
    return [NSDate dateFromString:string format:@"yyyy-MM-dd'T'HH:mm:ss.0'Z'"];
}

+ (NSString*)stringFromDate:(NSDate*)date format:(NSString*)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; // IOS-429
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:date];
}
+ (NSDate*)dateFromString:(NSString*)string format:(NSString*)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; // IOS-429
    [dateFormatter setDateFormat:format];
    return [dateFormatter dateFromString:string];
}
@end
