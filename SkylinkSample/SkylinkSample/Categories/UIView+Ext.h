//
//  UIView+Ext.h
//  SkylinkSample
//
//  Created by Charlie on 25/11/19.
//  Copyright © 2019 Romain Pellen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView(Ext)
- (void)removeSubviews;
- (void)aspectFitRectForSize:(CGSize)insideSize container:(UIView*)container;
- (void)aspectFillRectForSize:(CGSize)insideSize container:(UIView*)container;
@end

NS_ASSUME_NONNULL_END
