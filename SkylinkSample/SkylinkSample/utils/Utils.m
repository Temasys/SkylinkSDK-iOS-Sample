//
//  Utils.m
//  objc_SampleApp
//
//  Created by Charlie on 19/11/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

#import "Utils.h"
#import <UIKit/UIKit.h>

@implementation Utils
UIViewController * topVC(){
    UIWindow        *keyWindow = nil;
    NSArray         *windows = [[UIApplication sharedApplication]windows];
    for (UIWindow   *window in windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    return keyWindow.rootViewController;
}
@end

