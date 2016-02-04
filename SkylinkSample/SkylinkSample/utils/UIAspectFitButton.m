//
//  UIAspectFitButton.m
//  Skylink_Examples
//
//  Created by Romain Pellen on 16/12/2015.
//  Copyright © 2015 Temasys. All rights reserved.
//

#import "UIAspectFitButton.h"

@implementation UIAspectFitButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)layoutSubviews {
    [super layoutSubviews];
    for(UIView* buttonSubview in self.subviews) {
        if([buttonSubview isKindOfClass:[UIImageView class]])
            [buttonSubview setContentMode:UIViewContentModeScaleAspectFit];
    }
}

@end
