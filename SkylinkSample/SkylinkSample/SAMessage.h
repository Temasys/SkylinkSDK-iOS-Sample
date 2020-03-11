//
//  SAMessage.h
//  SkylinkSample
//
//  Created by Charlie on 9/3/20.
//  Copyright © 2020 Romain Pellen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum SAMessageType{
    SAMessageTypeSignaling,
    SAMessageTypeP2P
}SAMessageType;

@interface SAMessage : NSObject
@property(strong, nonatomic)NSString *data;
@property(assign, nonatomic)long long timeStamp;
@property(strong, nonatomic)NSString *sender;
@property(strong, nonatomic)NSString *target;
@property(assign, nonatomic)SAMessageType type;

- (instancetype)initWithData:(NSString *)data timeStamp:(long long)timeStamp sender:(nullable NSString *)sender target:(nullable NSString *)target type:(SAMessageType)type;
- (NSString *)typeToString;
- (BOOL)isPublic;
- (NSString *)isPublicString;
- (NSString *)timeStampString;
@end

NS_ASSUME_NONNULL_END

