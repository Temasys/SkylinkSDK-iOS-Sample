# SkylinkSDK iOS SampleApp Objective C

The Sample Application(SA), which uses the latest version of the Skylink SDK for iOS, demonstrates its use to provide embedded real time communication in the easiest way.
Excluding 'Settings', this App has 6 distinct view controllers, each of them demonstrating how to build the following features:

- One to one video call with Screen Share
- Multi party video call
- Multi party audio call
- Chatroom and custom messages
- File transfer
- Data transfer

## Code introduction  
The code should be self explanatory. Each view controller works by itself and there is minimal UI code due to to Storyboard usage. 
In each view controller, the main idea is to **configure and instantiate a connection to a room with the Skylink iOS SDK**. 
You will then be able to communicate with another peer joining the same room.  

##### Sample Code with Video and Audio 

    // Creating configuration
    SKYLINKConnectionConfig *config = [SKYLINKConnectionConfig new];
    [config setAudioVideoReceiveConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    [config setAudioVideoSendConfig:AudioVideoConfig_AUDIO_AND_VIDEO];
    
    // Creating SKYLINKConnection
    SKYLINKConnection *skylinkConnection = [[SKYLINKConnection alloc] initWithConfig:config callback:nil];
    self.skylinkConnection.lifeCycleDelegate = self;
    self.skylinkConnection.mediaDelegate = self;
    self.skylinkConnection.remotePeerDelegate = self;
	self.skylinkConnection = skylinkConnection;
    
    // Coonnecting to room
    [skylinkConnection connectToRoomWithAppKey:self.skylinkApiKey secret:self.skylinkApiSecret roomName:ROOM_NAME userData:nil callback:nil];


You can then control what happens in the room by **sending messages to the `SKYLINKConnection` instance** (like triggering a file transfer request for example), and **respond to events by implementing the delegate methods** from the 6 protocols.
Always set at least the [lifeCycleDelegate](https://cdn.temasys.io/skylink/skylinksdk/ios/latest/docs/html/Protocols/SKYLINKConnectionLifeCycleDelegate.html). For a list of all protocols, see [here](https://cdn.temasys.io/skylink/skylinksdk/ios/latest/docs/html/index.html)


Aditionally, in each view controller example's viewDidLoad/initWithCoder method, some properties are initialized.
A disconnect button is set in the navigation bar (left corner) as well as its selector implementation (called disconnect). An info button is set on the right corner, as well as its implementation (called showInfos). Those 2 navigation bar buttons selectors are the same in every View Controller example.

The rest of the example view controllers gives you 6 example usages of the Temasys iOS SDK.

## How to run the sample project

### Step-by-step guide

##### Prerequisites  
Please use Xcode 11

##### STEP 1  
It is recommended to install the SkylinkSDK for iOS via [cocoapods](http://cocoapods.org). If you do not have it installed, follow the below steps:

###### Installing Cocoapods  
Check that you have Xcode command line tools installed (Xcode > Preferences > Locations > Command line tools([?](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/)). If not, open the terminal and run `xcode-select --install`.
Install cocoa pods in the terminal: `$ sudo gem install cocoapods`

##### STEP 2  
Clone the repo or download the project.

##### STEP 3  
Navigate to the Sample App and Run `pod install`

##### STEP 4  
Open the .xcworkspace file

##### STEP 5  
Follow the instructions [here](https://temasys.io/creating-an-account-generating-a-key/) to create an App and a key on the Temasys Console.

##### STEP 6   
Set your App Key and secret in Constant.h. You may also alter the room names here.
    
    NSString *APP_KEY = @"ENTER APP KEY HERE";
    NSString *APP_SECRET = @"ENTER SECRET HERE";

    NSString *ROOM_ONE_TO_ONE_VIDEO = @"ROOM_ONE_TO_ONE_VIDEO";
    NSString *ROOM_MULTI_VIDEO = @"ROOM_MULTI_VIDEO";
    NSString *ROOM_AUDIO = @"ROOM_AUDIO";
    NSString *ROOM_MESSAGES = @"MESSAGES-ROOM";
    NSString *ROOM_FILE_TRANSFER = @"ROOM_FILE_TRANSFER";
    NSString *ROOM_DATA_TRANSFER = @"ROOM_DATA_TRANSFER";


##### STEP 7  
Build and Run. You're good to go!

##### Please Note
The XCode Simulator does not support video calls.  
If you have connected a phone, ensure it is unlocked and the appropriate team is selected under Signing & Capabilities.    

### Resources


##### SDK documentation  
For more information on the usage of the SkylinkSDK for iOS, please refer to [SkylinkSDK for iOS Readme](https://github.com/Temasys/SKYLINK-iOS/blob/master/README.md)

##### Subscribe  
Star this repo to be notified of new release tags. You can also view release notes on our [support portal](http://support.temasys.com.sg/en/support/solutions/folders/12000009706)

##### Feedback  
Please do not hesitate to reach get in touch with us if you encounter any issue or if you have any feedback or suggestions on how we can improve the Skylink SDK for iOS or Sample Applications. You can raise tickets on our [support portal](http://support.temasys.io/).

##### Copyright and License  
Copyright 2019 Temasys Communications Pte Ltd Licensed under APACHE 2.0  


#### Tutorials and FAQs

[Getting started with Temasys iOS SDK for iOS](http://temasys.io/getting-started-skylinksdk-ios/)  
[Handle the video view stretching](http://temasys.io/a-simple-solution-for-video-stretching/)  
[FAQs](http://support.temasys.com.sg/support/solutions/12000000562)
  

Also checkout our Skylink SDKs for [Web](http://skylink.io/web/) and [Android](http://skylink.io/android)

*This document was edited for Temasys iOS SDK version 2.0.0*