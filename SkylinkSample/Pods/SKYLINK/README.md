# Temasys iOS SDK
[![Version](https://img.shields.io/cocoapods/v/MyLibrary.svg?style=flat)](http://cocoadocs.org/docsets/SKYLINK)  [![License](https://img.shields.io/cocoapods/l/MyLibrary.svg?style=flat)](http://cocoadocs.org/docsets/SKYLINK) [![Platform](https://img.shields.io/cocoapods/p/MyLibrary.svg?style=flat)](http://cocoadocs.org/docsets/SKYLINK)

The **Temasys iOS SDK** lets you build real time webRTC applications with voice calling, video chat, P2P file sharing or data and messages exchange. Go multi-platform with our [Web](http://skylink.io/web/) and [Android](http://skylink.io/android) SDKs.

## Documentation & Sample App

Check out the documentation and our sample app to get usage instructions and examples.

| Description | Link |
| --- | --- |
| Temasys iOS SDK documentation | https://cdn.temasys.io/skylink/skylinksdk/ios/latest/docs/index.html |
| Sample App (Github) | http://github.com/Temasys/SkylinkSDK-iOS-Sample |

## Requirements
Your project should use ARC and target iOS 8 or higher.

## Installation

The Temasys iOS SDK (formerly SkylinkSDK for iOS) is available through [CocoaPods](http://cocoapods.org). 
To install it, simply add the following line to your Podfile:

    pod "SKYLINK"

> To use this SDK, you need to **get you API key** at http://console.temasys.io/register


### Use the Temasys iOS SDK in a Swift project

To create a Swift project using Teamsys iOS SDK, follow these steps:

- Create new Xcode project
- Run  `pod init`
- Your Podfile should look like that: 
```
    use_frameworks!
    target 'MyTarget' do
    pod "SKYLINK"
    end
```
- Run `pod install`
- Create the `Project-Bridging-Header.h` and refer to it in build settings (swift compiler section)
- Add `#import <SKYLINK/SKYLINK.h>` to the newlly created file
You should be able to run your project after this, and use Temasys iOS SDK with Swift.

### Configuring Settings

- After running 'pod install', use the .xcworkspace file and always work with this from now on (instead of the .xcodeproj file).
- For each target planned to use Temasys iOS SDK, go to Build settings  (make sure “all” is selected) > Build Options > Enable bit code and set it to NO. This will avoid the “…does not contain bitcode” message
- If you get the error “The resource could not be loaded because the App Transport Security policy requires the use of a secure connection”, edit your info.plist by adding a NSAppTransportSecurity key as Dictionary, and add a sub-key named NSAllowsArbitraryLoads as boolean set to YES.
- Optionally, if you want your app to be able to process audio even when the users leaves the app or locks the device, just enable the VoIP background capability or the audio background capability in the target’s “capabilities” tab.

## Start coding !

The Temasys iOS SDK is designed to be simple to use. The main idea when using it is to prepare and create a connection to a "room" via the Temasys platform. After that, you will be able to send messages to the connection and implement the desired protocols to control what happens between the local device and the peers connected to the same "room".

To learn even more, please consult the follwing ressources:

### Tutorials
 
| Tutorial | Link |
| --- | --- |
| Getting started with Temasys iOS SDK for iOS | http://temasys.io/getting-started-skylinksdk-ios/ |
| Handle the video view stretching | http://temasys.io/a-simple-solution-for-video-stretching/ |

----------

**Other Resources**
==========================

Support portal
-------
If you encounter any issues or have any enquiries regarding the Temasys iOS SDK, drop us a note on our [support portal](http://support.temasys.io/support/login) and we would be happy to help! 


You can subscribe to Temasys iOS SDK releases notes: http://support.temasys.io/support/solutions/articles/12000012359-how-can-i-subscribe-to-release-notes-for-skylink-



