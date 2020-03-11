//
//  SAMessage.m
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import "SAMessage.h"

@implementation SAMessage
- (instancetype)initWithData:(NSString *)data timeStamp:(long long)timeStamp sender:(NSString *)sender target:(NSString *)target type:(SAMessageType)type{
    if(self = [super init]){
        self.data = data;
        self.timeStamp = timeStamp;
        self.sender = sender;
        self.target = target;
        self.type = type;
    }
    return self;
}
- (NSString *)typeToString{
    if (self.type == SAMessageTypeSignaling) {
        return @"Signaling";
    }else{
        return @"P2P";
        
    }
}
- (BOOL)isPublic{
    return (self.target == nil);
}
- (NSString *)isPublicString{
    return self.isPublic ? @"Public" : @"Private";
}
- (NSString *)timeStampString{
    NSDate *dateTS = [NSDate dateFromTimeStamp:self.timeStamp];
    return [dateTS skylinkDateString];
}
@end
