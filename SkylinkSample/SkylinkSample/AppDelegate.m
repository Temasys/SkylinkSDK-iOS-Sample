//
//  AppDelegate.m
//  SkylinkSample/Users/romainpellen/Desktop/Bitbucket/Temasys/SkylinkSDK-iOS-Sample/SkylinkSample/SkylinkSample
//
//  Created by Temasys on 01/02/2016.
//  Copyright © 2016 Temasys. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "Constant.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    signal(SIGPIPE, SIG_IGN); // Resolve SIGPIPE, as sugested by Apple doc.
    MyLog(@"- SKYLINK SampleApp launched -");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)createFolder
{
    NSArray *allDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = allDirectories[0];
    appFilesFolder = [documentDirectory stringByAppendingPathComponent:@"app_files"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appFilesFolder]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL URLWithString:appFilesFolder] withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) MyLog(@"%@", error.localizedDescription);
    }
}
@end

