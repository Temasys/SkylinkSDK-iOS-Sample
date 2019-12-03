//
//  UIAlertController+Ext.m
//  objc_SampleApp
//
//  Created by Charlie on 18/11/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

#import "UIAlertController+Ext.h"
#import "Utils.h"

//@interface UIAlertController(Ext)
//
//@end

@implementation UIAlertController(Ext)

void showAlert(NSString *title, NSString* message){
    UIAlertController * _alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *_okBtn = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [_alert addAction:_okBtn];
    [topVC() presentViewController:_alert animated:YES completion:nil];
}

void showAlertAutoDismiss(NSString *title, NSString *message, float duration, UIViewController *vc){
    UIAlertController * _alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [vc presentViewController:_alert animated:YES completion:nil];
//    __weak typeof(vc) _weakVC = vc;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_alert dismissViewControllerAnimated:YES completion:nil];
        
    });
}
+ (void)showAlertWithAutoDisappearTitle:(NSString *)title message:(NSString *)message duration:(CGFloat)duration onViewController:(UIViewController *)viewController
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [viewController presentViewController:alertVc animated:YES completion:^{
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alertVc dismissViewControllerAnimated:YES completion:^{
        }];
    });
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
