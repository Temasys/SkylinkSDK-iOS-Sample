

**Temasys iOS SDK** Sample App
==========================

**WebRTC** powered App
-------
WebRTC is **real-time audio, video and data exchange** for your **website and native app**.

With WebRTC browsers and apps learn to talk to each other instead of just to web servers. They can share audio and video streams from your microphone and camera, exchange files and images or just send and receive simple messages the fastest possible way: **peer-to-peer**.

**Temasys iOS SDK** demo
-------
The Temasys iOS SDK is a cross platform solution for building WebRTC rich messaging applications. You also might want to check the Android and JavaScript SDKs on http://skylink.io.

*This sample application and it's code is intended to demonstrate use of the Temasys iOS SDK in various use-cases.*
> To use this sample app, you need to **get you API key** at http://console.temasys.io/register

This App has 6 distinct view controllers, each of them demonstrate how to build the following features:

- One to one video call
- Multi party video call
- Multi party audio call
- Chatroom and custom messages
- File transfers
- Data transfer

## Documentation & SDK repo

Check out the documentation and our sample app to get usage instructions and examples.

| Description | Link |
| --- | --- |
| Temasys iOS SDK documentation | https://cdn.temasys.io/skylink/skylinksdk/ios/latest/docs/index.html |
| SDK (Github) |  http://github.com/Temasys/SKYLINK-iOS |


----------

**Usage**
==========================
Installation
-------

This sample app uses SkylinkSDK for iOS: [http://github.com/Temasys/SKYLINK-iOS](http://github.com/Temasys/SKYLINK-iOS)

> It is recommended to install the SDK via **cocoapods**, if you don't have it installed follow these steps:
>  - Check that you have Xcode command line tools installed (Xcode > Preferences > Locations > Command line tools). If not, open the terminal and run `xcode-select --install` ([more details here](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/) if needed).
>  - Install cocoa pods in the terminal: `$ sudo gem install cocoapods`
>  
>  *Cocoapods website: [cocoapods.org](http://cocoapods.org).*

- Clone the repo or download the project.
- Run `pod install` .  
- Open the .xcworkspace file and run the universal app.

Code introduction
-------
The code should be self explanatory: each view controller works by itself and there is very few UI code thanks to Storyoard usage. 
In each view controller, the main idea is to **configure and instanciate a connection to a room with the Temasys iOS SDK (formerly Skylink SDK for iOS)**. 
You will then be able to communicate with other peer joining the same room.

    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    config.video = YES;
    config.audio = YES;
    config.dataChannel = YES;
    config.fileTransfer = YES;
    config.timeout = 30;
    config.userInfo = @{@"customKey" : customValue, ...};
    // Creating SKYLINKConnection
    self.skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config appKey:@"MY-KEY"];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.mediaDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
    self.skylinkConnection.messagesDelegate = self;
    self.skylinkConnection.fileTransferDelegate = self;
    // Connecting to a room
    [self.skylinkConnection connectToRoomWithSecret:@"MY-SECRET" roomName:@"A-ROOM-NAME" userInfo:nil];

You can then control what happens in to room by **sending messages to the `SKYLINKConnection` instance** (like triggering a file transfer request for example), and **respond to events by implementing the delegate methods** from the 5 protocols.
Always set at least the `lifeCycleDelegate`.

> **Checkout the documentation for the complete set of informations.  http://skylink.io/ios/**

Aditionally, in each view controller example's viewDidLoad/initWithCoder method, some properties are initialized.
A disconnect button is set in the navigation bar (left corner) as well as its selector implementation (called disconnect). An info button is set on the right corner, as well as its implementation (called showInfos). Those 2 navigation bar buttons selectors are the same in every VC example.

The rest of the example view controllers gives you 5 example usages of the Temasys iOS SDK.

**Resources**
==========================

Support portal
-------
 If you encounter any issues or have any enquiries regarding the Temasys iOS SDK, drop us a note on our [support portal](http://support.temasys.io/support/login) and we would be happy to help! 
=======
 If you encounter any issues or have any enquiries regarding Skylink, drop us a note on our [support portal](http://support.temasys.io/support/login) and we would be happy to help! 

### Tutorials

| Tutorial | Link |
| --- | --- |
| Getting started with Temasys iOS SDK for iOS | http://temasys.io/getting-started-skylinksdk-ios/ |
| Handle the video view stretching | http://temasys.io/a-simple-solution-for-video-stretching/ |


Skylink, by **Temasys**
-------

Check our company websites:
- **Skylink**: http://skylink.io
- By **Temasys**: http://temasys.io
Also checkout our Skylink SDKs for [Web](http://skylink.io/web/) and [Android](http://skylink.io/android)

Other library used (via cocoapods)
-------

- UIAlertView-Blocks: https://github.com/jivadevoe/UIAlertView-Blocks


----------

*This document was edited for Temasys iOS SDK version 1.0.9*



