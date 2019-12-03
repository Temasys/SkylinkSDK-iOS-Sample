//
//  StatsView.h
//  SkylinkSample
//
//  Created by Yuxi Liu on 5/9/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum Status {
    StatusInput = 0,
    StatusSent,
    StatusReceived,
    StatusAll
} Status;

@interface Stats : NSObject
@property(nonatomic, copy) NSString *inputWidth;
@property(nonatomic, copy) NSString *inputHeight;
@property(nonatomic, copy) NSString *inputFPS;
@property(nonatomic, copy) NSString *sentWidth;
@property(nonatomic, copy) NSString *sentHeight;
@property(nonatomic, copy) NSString *sentFPS;
@property(nonatomic, copy) NSString *receivedWidth;
@property(nonatomic, copy) NSString *receivedHeight;
@property(nonatomic, copy) NSString *receivedFPS;

- (instancetype)initWithDict:(NSDictionary *)dict;
@end

@class Stats;
@interface StatsView : UIView
- (void)setupViewWithStats:(Stats *)stats status:(Status)status;
@end

NS_ASSUME_NONNULL_END
