//
//  Constant.h
//  SkylinkSample
//
//  Created by Temasys on 5/9/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *APP_KEY;
extern NSString *APP_SECRET;
extern NSString *ROOM_NAME;
//extern NSDictionary *APP_KEYS;

extern NSString *ROOM_ONE_TO_ONE_VIDEO;
extern NSString *ROOM_MULTI_VIDEO;
extern NSString *ROOM_AUDIO;
extern NSString *ROOM_MESSAGES;
extern NSString *ROOM_FILE_TRANSFER;
extern NSString *ROOM_DATA_TRANSFER;

extern NSString *appFilesFolder;

//NSDictionary* APP_KEYS(void);
//NSDictionary* ENCRYPTION_SECRETS(void);
#define USER_NAME UIDevice.currentDevice.name


#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width


#define iPhone4 [[UIScreen mainScreen] bounds].size.height == 480
#define iPhone5 [[UIScreen mainScreen] bounds].size.height == 568
#define iPhone6 [[UIScreen mainScreen] bounds].size.height == 667
#define iPhone6Plus [[UIScreen mainScreen] bounds].size.height == 736
#define iPhoneX [[UIScreen mainScreen] bounds].size.height == 812
#define iPhoneXR_XSMAX [[UIScreen mainScreen] bounds].size.height == 896


#define iOS7 [[UIDevice currentDevice] systemVersion].floatValue < 8.0
#define iOS8 [[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0
#define iOS9 [[UIDevice currentDevice] systemVersion].floatValue >= 9.0 && [[UIDevice currentDevice] systemVersion].floatValue < 10.0
#define iOS10 [[UIDevice currentDevice] systemVersion].floatValue >= 10.0 && [[UIDevice currentDevice] systemVersion].floatValue < 11.0
#define iOS11 [[UIDevice currentDevice] systemVersion].floatValue >= 11.0 && [[UIDevice currentDevice] systemVersion].floatValue < 12.0
#define iOS12 [[UIDevice currentDevice] systemVersion].floatValue >= 12.0 && [[UIDevice currentDevice] systemVersion].floatValue < 13.0
#define iOS13 [[UIDevice currentDevice] systemVersion].floatValue >= 13.0 && [[UIDevice currentDevice] systemVersion].floatValue < 14.0
#define iOS11Above [[UIDevice currentDevice] systemVersion].floatValue >= 11.0


#define UIRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define UIRGBAColor(r, g, b, alpha) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:alpha]
#define UIRandomColor UIRGBColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))
#define UIGlobalBackgroundColor UIRGBColor(242, 243, 244)
#define UIGlobalTextLightColor UIRGBColor(155, 155, 155)
#define UIGlobalTextDarkColor UIRGBColor(74, 74, 74)

#ifdef DEBUG
#define MyLog(...) NSLog(__VA_ARGS__)
#else
#define MyLog(...)
#endif

@interface SAConstants : NSObject
+(instancetype)shared;
@property(strong, nonatomic) NSDictionary *APP_KEYS;
@property(strong, nonatomic) NSMutableDictionary *ENCRYPTION_SECRETS;
+ (void)switchOutput;
@end
