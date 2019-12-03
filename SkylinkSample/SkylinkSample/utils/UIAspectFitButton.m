//
//  UIAspectFitButton.m
//  Skylink_Examples
//
//  Created by Temasys on 16/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "UIAspectFitButton.h"

@implementation UIAspectFitButton

-(void)layoutSubviews {
    [super layoutSubviews];
    for(UIView *buttonSubview in self.subviews)
        if ([buttonSubview isKindOfClass:[UIImageView class]]) [buttonSubview setContentMode:UIViewContentModeScaleAspectFit];
}

@end
