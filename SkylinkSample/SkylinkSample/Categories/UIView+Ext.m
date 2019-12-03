//
//  UIView+Ext.m
//  SkylinkSample
//
//  Created by Charlie on 25/11/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import "UIView+Ext.h"

@implementation UIView(Ext)
- (void)removeSubviews{
    while (self.subviews.count>0) {
        [self.subviews.firstObject removeFromSuperview];
    }
}
- (void)aspectFitRectForSize:(CGSize)insideSize container:(UIView*)container{
    if (!container ||
        insideSize.width<=0 ||
        insideSize.height<=0) {
        return;
    }
    
    CGFloat originRate = insideSize.width/insideSize.height;
    CGFloat containerRate = container.frame.size.width/container.frame.size.height;
    CGRect resultFrame = CGRectMake(0, 0, 0, 0);
    if (originRate > containerRate){
        resultFrame.size.width = container.frame.size.width;
        resultFrame.size.height = container.frame.size.width/originRate;
    }else{
        resultFrame.size.height = container.frame.size.height;
        resultFrame.size.width = container.frame.size.height*originRate;
    }
    resultFrame.origin.x = container.frame.size.width/2 - resultFrame.size.width/2;
    resultFrame.origin.y = container.frame.size.height/2 - resultFrame.size.height/2;
    self.frame = resultFrame;
}
- (void)aspectFillRectForSize:(CGSize)insideSize container:(UIView*)container{
    if (!container ||
        insideSize.width<=0 ||
        insideSize.height<=0) {
        return;
    }
    self.frame = container.frame;
    /*var maxFloat: CGFloat = 0
    if container.frame.size.height > container.frame.size.width {
        maxFloat = container.frame.size.height
    } else if container.frame.size.height < container.frame.size.width {
        maxFloat = container.frame.size.width
    } else {
        maxFloat = 0
    }
    var aspectRatio: CGFloat = 0
    if insideSize.height != 0 {
        aspectRatio = insideSize.width / insideSize.height
    } else {
        aspectRatio = 1
    }
    var frame = CGRect(x: 0, y: 0, width: container.frame.size.width, height: container.frame.size.height)
    if insideSize.width < insideSize.height {
        frame.size.width = maxFloat
        frame.size.height = frame.size.width / aspectRatio
    } else {
        frame.size.height = maxFloat;
        frame.size.width = frame.size.height * aspectRatio
    }
    frame.origin.x = (container.frame.size.width - frame.size.width) / 2
    frame.origin.y = (container.frame.size.height - frame.size.height) / 2
    self.frame = frame*/
}
@end
