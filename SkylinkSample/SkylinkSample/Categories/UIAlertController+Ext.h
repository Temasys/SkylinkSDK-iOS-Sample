//
//  UIAlertController+Ext.h
//  objc_SampleApp
//
//  Created by Charlie on 18/11/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController(Ext)
void showAlert(NSString *title, NSString* message);
void showAlertAutoDismiss(NSString *title, NSString *message, float duration, UIViewController *vc);
+ (void)showAlertWithAutoDisappearTitle:(NSString *)title message:(NSString *)message duration:(CGFloat)duration onViewController:(UIViewController *)viewController;
@end

//NS_ASSUME_NONNULL_END
