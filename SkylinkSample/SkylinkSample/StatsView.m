//
//  StatsView.m
//  SkylinkSample
//
//  Created by Yuxi Liu on 5/9/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import "StatsView.h"

@implementation Stats

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        self.inputWidth = dict[@"FrameWidthInput"] ? dict[@"FrameWidthInput"] : @"480";
        self.inputHeight = dict[@"FrameHeightInput"] ? dict[@"FrameHeightInput"] : @"640";
        self.inputFPS = dict[@"FrameRateInput"] ? dict[@"FrameRateInput"] : @"30";
        self.sentWidth = dict[@"FrameWidthSent"] ? dict[@"FrameWidthSent"] : @"0";
        self.sentHeight = dict[@"FrameHeightSent"] ? dict[@"FrameHeightSent"] : @"0";
        self.sentFPS = dict[@"FrameRateSent"] ? dict[@"FrameRateSent"] : @"0";
        self.receivedWidth = dict[@"FrameWidthReceived"] ? dict[@"FrameWidthReceived"] : @"0";
        self.receivedHeight = dict[@"FrameHeightReceived"] ? dict[@"FrameHeightReceived"] : @"0";
        self.receivedFPS = dict[@"FrameRateReceived"] ? dict[@"FrameRateReceived"] : @"0";
    }
    return self;
}
@end

@interface StatsView()
@property (weak, nonatomic) IBOutlet UILabel *inputWidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *inputHeightLabel;
@property (weak, nonatomic) IBOutlet UILabel *inputFPSLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentWidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentHeightLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentFPSLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedWidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedHeightLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedFPSLabel;
@end

@implementation StatsView

- (void)setupViewWithStats:(Stats *)stats status:(Status)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == StatusInput) {
            self.inputWidthLabel.text = stats.inputWidth;
            self.inputHeightLabel.text = stats.inputHeight;
            self.inputFPSLabel.text = stats.inputFPS;
        }
        if (status == StatusSent) {
            self.sentWidthLabel.text = stats.sentWidth;
            self.sentHeightLabel.text = stats.sentHeight;
            self.sentFPSLabel.text = stats.sentFPS;
        }
        if (status == StatusReceived) {
            self.receivedWidthLabel.text = stats.receivedWidth;
            self.receivedHeightLabel.text = stats.receivedHeight;
            self.receivedFPSLabel.text = stats.receivedFPS;
        }
        if (status == StatusAll) {
            self.inputWidthLabel.text = stats.inputWidth;
            self.inputHeightLabel.text = stats.inputHeight;
            self.inputFPSLabel.text = stats.inputFPS;
            self.sentWidthLabel.text = stats.sentWidth;
            self.sentHeightLabel.text = stats.sentHeight;
            self.sentFPSLabel.text = stats.sentFPS;
            self.receivedWidthLabel.text = stats.receivedWidth;
            self.receivedHeightLabel.text = stats.receivedHeight;
            self.receivedFPSLabel.text = stats.receivedFPS;
        }
    });
}
@end
