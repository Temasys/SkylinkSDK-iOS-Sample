//
//  NSString+Ext.m
//  SkylinkSample
//
//  Created by Charlie on 10/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import "NSString+Ext.h"

@implementation NSString(Ext)
- (BOOL)isNotEmpty{
    if (self && self.length>0) {
        return YES;
    }
    return NO;
}
@end
