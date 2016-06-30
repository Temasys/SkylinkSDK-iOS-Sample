//
//  AppDelegate.swift
//  SkylinkSample/Users/romainpellen/Desktop/Bitbucket/Temasys/SkylinkSDK-iOS-Sample/SkylinkSample/SkylinkSample
//
//  Created by Phyo Pwint  on 5/4/16.
//  Copyright © 2016  Temasys . All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.didSessionRouteChange(_:)), name: AVAudioSessionRouteChangeNotification, object: nil)
        // to set the speakers as default audio route
        signal(SIGPIPE, SIG_IGN)
        return true
    }
    
    func didSessionRouteChange(notification: NSNotification) {
        let interuptionDict: NSDictionary = notification.userInfo!
        let routeChangeReason = UInt((interuptionDict.valueForKey(AVAudioSessionRouteChangeReasonKey)?.integerValue!)!)
        //Output Voice Through Specker
        
        switch(routeChangeReason) {
        case AVAudioSessionRouteChangeReason.CategoryChange.rawValue:
            let session = AVAudioSession.sharedInstance()
            do {
                try session.overrideOutputAudioPort (AVAudioSessionPortOverride.Speaker)
            }
            catch let error as NSError {
                error.description
            }
            break
            default:
            break
        }
    }
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

