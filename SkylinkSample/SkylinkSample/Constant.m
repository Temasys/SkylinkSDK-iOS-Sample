//
//  Constant.m
//  SkylinkSample
//
//  Created by Temasys on 5/9/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

#import "Constant.h"
#import <AVFoundation/AVFoundation.h>

NSString *APP_KEY = @"Enter AppKey";
NSString *APP_SECRET = @"Enter AppSecret";
NSString *ROOM_NAME = @"rt";

NSString *ROOM_ONE_TO_ONE_VIDEO = @"rt";
NSString *ROOM_MULTI_VIDEO = @"ROOM_MULTI_VIDEO";
NSString *ROOM_AUDIO = @"ROOM_AUDIO";
NSString *ROOM_MESSAGES = @"MESSAGES-ROOM";
NSString *ROOM_FILE_TRANSFER = @"ROOM_FILE_TRANSFER";
NSString *ROOM_DATA_TRANSFER = @"ROOM_DATA_TRANSFER";

NSString *appFilesFolder = @"";
@implementation SAConstants

+ (instancetype)shared{
    static SAConstants *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        //initial keys
        shared.APP_KEYS = @{@"APP_KEY1": @"APP_SECRET1",
                            @"APP_KEY2": @"APP_SECRET2",
                            @"APP_KEY3": @"APP_SECRET3"};
        shared.ENCRYPTION_SECRETS = [NSMutableDictionary dictionaryWithDictionary: @{@"key1": @"secret1",
                                      @"key2": @"secret2",
                                      @"key3": @"secret3"}];
    });
    return shared;
}

@end

