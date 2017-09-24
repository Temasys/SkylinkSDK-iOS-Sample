//
//  TEMAConnectionManager.h
//
//  Created by Temasys.
//  Copyright (c) 2015 TemaSys. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>


/**
 @typedef SKYLINKAssetType
 @brief Asset types to help the framework read the files.
 @constant SKYLINKAssetTypeFile Files within the app sandbox.
 @constant SKYLINKAssetTypeMusic Files from the music library.
 @constant SKYLINKAssetTypePhoto Photo and Video content from the Photo Library.
 */
typedef enum SKYLINKAssetType {
    SKYLINKAssetTypeFile = 1,
    SKYLINKAssetTypeMusic,
    SKYLINKAssetTypePhoto
} SKYLINKAssetType;

@class UIView;
@class SKYLINKConnection;
@class SKYLINKPeerMediaProperties;

// All the messages of the following protocols are sent on the main thread

/**
 @brief Protocol to receive events related to the lifecycle of the connection.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionLifeCycleDelegate <NSObject>

@optional

/**
 @brief First delegate method called on the delegate upon successful or unsuccessful connection.
 @discussion If the connection is successfull, this method gets called just before the connection notifies the other peers in the room that the local user entered it.
 @param connection The underlying connection object.
 @param errorMessage Error message in case the connection is unsuccessful.
 @param isSuccess Flag to specify whether the connection was successful.
 */
- (void)connection:(SKYLINKConnection*)connection didConnectWithMessage:(NSString*)errorMessage success:(BOOL)isSuccess; 

/**
 @brief Called upon successful capturing and rendering of the local front camera.
 @param connection The underlying connection object.
 @param userVideoView The video view of the connecting client.
 */
- (void)connection:(SKYLINKConnection*)connection didRenderUserVideo:(UIView*)userVideoView;

/**
 @brief Called when a remote peer locks/unlocks the room.
 @param connection The underlying connection object.
 @param lockStatus The status of the lock.
 @param peerId The unique id of the peer who originated the action.
 */
- (void)connection:(SKYLINKConnection*)connection didLockTheRoom:(BOOL)lockStatus peerId:(NSString*)peerId;

/**
 @brief Called when a warning is received from the underlying system.
 @param connection The underlying connection object.
 @param message Warning message from the underlying system.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveWarning:(NSString*)message;

/**
 @brief Called when the client is disconnected from the server.
 @param connection The underlying connection object.
 @param errorMessage Message specifying the reason of disconnection.
 */
- (void)connection:(SKYLINKConnection*)connection didDisconnectWithMessage:(NSString*)errorMessage;

@end

/**
 @brief Protocol to receive events related to remote peers.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionRemotePeerDelegate <NSObject>

@optional

/**
 @brief Called when a remote peer joins the room.
 @param connection The underlying connection object.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 @param pmProperties An object defining peer media properties of the joining peer.
 @param peerId The unique id of the joining peer.
 */
- (void)connection:(SKYLINKConnection*)connection didJoinPeer:(id)userInfo mediaProperties:(SKYLINKPeerMediaProperties*)pmProperties peerId:(NSString*)peerId;

/**
 @brief Called upon receiving a remote video stream.
 @param connection The underlying connection object.
 @param peerVideoView The video view of the joining peer.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didRenderPeerVideo:(UIView*)peerVideoView peerId:(NSString*)peerId;

/**
 @brief Called upon receiving an update about a user info.
 @param connection The underlying connection object.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveUserInfo:(id)userInfo peerId:(NSString*)peerId;

/**
 @brief Called when a peer has left the room implictly or explicitly.
 @param connection The underlying connection object.
 @param errorMessage Error message in case the peer is left due to some error.
 @param peerId The unique id of the leaving peer.
 */
- (void)connection:(SKYLINKConnection*)connection didLeavePeerWithMessage:(NSString*)errorMessage peerId:(NSString*)peerId;

@end

/**
 @brief Protocol to receive events related to media i.e. audio/video.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionMediaDelegate <NSObject>

@optional

/**
 @brief Called when the dimensions of the video view are changed.
 @param connection The underlying connection object.
 @param videoSize The size of the respective video.
 @param videoView The video view for which the size was sent.
 */
- (void)connection:(SKYLINKConnection*)connection didChangeVideoSize:(CGSize)videoSize videoView:(UIView*)videoView;

/**
 @brief Called when a peer mutes/unmutes its audio.
 @param connection The underlying connection object.
 @param isMuted Flag to specify whether the audio is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didToggleAudio:(BOOL)isMuted peerId:(NSString*)peerId;

/**
 @brief Called when a peer mutes/unmutes its video.
 @param connection The underlying connection object.
 @param isMuted Flat to specify whether the video is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didToggleVideo:(BOOL)isMuted peerId:(NSString*)peerId;

@end

/**
 @brief Protocol to receive events related to remote peer messages.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionMessagesDelegate <NSObject>

@optional

/**
 @brief Called upon receiving a private or public message.
 @param connection The underlying connection object.
 @param message User defined message. May be an NSString, NSDictionary or NSArray.
 @param isPublic Flag to specify whether the message was a broadcast.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveCustomMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId;

/**
 @brief Called upon receiving a data channel chat message.
 @param connection The underlying connection object.
 @param message User defined message. May be an NSString, NSDictionary or NSArray.
 @param isPublic Flag to specify whether the message was a broadcast.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveDCMessage:(id)message public:(BOOL)isPublic peerId:(NSString*)peerId;

/**
 @brief Called upon receiving binary data on data channel.
 @param connection The underlying connection object.
 @param data Binary data.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveBinaryData:(NSData*)data peerId:(NSString*)peerId;

@end

/**
 @brief Protocol to receive events related to file transfer.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionFileTransferDelegate <NSObject>

@optional

/**
 @brief Called upon receiving a file transfer request from a peer.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceiveRequest:(NSString*)filename peerId:(NSString*)peerId;

/**
 @brief Called upon receiving a file transfer permission from a peer.
 @param connection The underlying connection object.
 @param isPermitted Flag to specify whether the request was accepted.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didReceivePermission:(BOOL)isPermitted filename:(NSString*)filename peerId:(NSString*)peerId;

/**
 @brief Called when the file being transferred is halted.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param message The message specifying reason for the file transfer drop.
 @param isExplicit Flag to specify whether the transfer was halted explicity by the sender.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didDropTransfer:(NSString*)filename reason:(NSString*)message isExplicit:(BOOL)isExplicit peerId:(NSString*)peerId;

/**
 @brief Called upon every file transfer progress update.
 @param connection The underlying connection object.
 @param percentage The perccentage representing the progress of the transfer (CGFloat from 0 to 1).
 @param isOutgoing Boolean to specify if the transfer is a file beign sent (value would be YES) or received (value would be NO).
 @param filename The name of the file in transmission.
 @param peerId The unique id of the peer thie file is sent to or received from.
 @discussion Alternatively, if many of your objects need to get these informations, it can register to the notification with identifier: @"SKYLINKFileProgress".
 */
- (void)connection:(SKYLINKConnection*)connection didUpdateProgress:(CGFloat)percentage isOutgoing:(BOOL)isOutgoing filename:(NSString*)filename peerId:(NSString*)peerId;


/**
 @brief Called upon file transfer completion.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param fileData NSData object holding the data transferred.
 @param peerId The unique id of the peer.
 */
- (void)connection:(SKYLINKConnection*)connection didCompleteTransfer:(NSString*)filename fileData:(NSData*)fileData peerId:(NSString*)peerId;

@end

/**
 @brief Protocol to receive events related to stats.
 @discussion Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionStatsDelegate <NSObject>
@optional
/**
 @brief Called upon webRTC stats delivery.
 @param connection The underlying connection object.
 @param stats A dictionary with stats name as keys and values as NSString values.
 @param peerId The unique id of the peer.
 @param mediaDirection int indicating the related media direction (mediaSent: 1, mediaReceived: 2).
 */
-(void)connection:(SKYLINKConnection *)connection didGetWebRTCStats:(NSDictionary *)stats forPeerId:(NSString *)peerId mediaDirection:(int)mediaDirection;
@end


/**
 @brief Protocol to receive backend events related to room recording (BETA).
 @discussion This works only on Skylink Media Relay enabled App Keys. Delegate methods are called on the main thread.
 */
@protocol SKYLINKConnectionRecordingDelegate <NSObject>

@optional

/**
 @brief Called upon recording start event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingID The id of the generated recording.
 @discussion This will be triggered after you call startRecording successfully.
 */
- (void)connection:(SKYLINKConnection*)connection recordingDidStartWithID:(NSString *)recordingID;

/**
 @brief Called upon recording stop event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingID The id of the recording.
 @discussion This will be triggered after you call stopRecording successfully or if the backend notifies of recording stoped.
 */
- (void)connection:(SKYLINKConnection*)connection recordingDidStopWithID:(NSString *)recordingID;
/**
 @brief Called upon recording error event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingID The id of the recording (might be nil if unknown).
 @param errorMessage The error description as a string.
 */
- (void)connection:(SKYLINKConnection*)connection recording:(NSString *)recordingID didError:(NSString *)errorMessage;
/**
 @brief Called upon recording completion event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingId The id of the recording.
 @param videoLink The mixing recording URL as a string.
 @param peerId The peerId who's recording the link is for. If nil then the URL is a mixin recording link.
 @discussion For this to be called you need to make sure the app key used is configured for recording.
 */
- (void)connection:(SKYLINKConnection*)connection recordingVideoLink:(NSString *)videoLink peerId:(NSString *)peerId recordingId:(NSString *)recordingId;

@end


/**
 @brief Class representing the handshaking peer properties.
 @discussion This class is used in the delegate method called when a peer joins the room to carry informations about the joining peer media properties.
 */
@interface SKYLINKPeerMediaProperties : NSObject

/**
 @brief whether the peer has audio.
 */
@property (nonatomic, unsafe_unretained) BOOL hasAudio;
/**
 @brief is audio stereo.
 @discussion if 'hasAudio' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) BOOL isAudioStereo;
/**
 @brief is audio muted.
 @discussion if 'hasAudio' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) BOOL isAudioMuted;
/**
 @brief whether the peer has video
 */
@property (nonatomic, unsafe_unretained) BOOL hasVideo;
/**
 @brief is video muted.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) BOOL isVideoMuted;
/**
 @brief width of the video frame.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) NSInteger videoWidth;
/**
 @brief height of the video frame.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) NSInteger videoHeight;
/**
 @brief frame rate of the video.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, unsafe_unretained) NSInteger videoFrameRate;

@end

/**
 @discussion The class representing the conversation configuration.
 */
@interface SKYLINKConnectionConfig : NSObject

/**
 @brief enable/disable audio.
 @discussion Default value is NO. This is a convinience property to set both sendAudio and receiveAudio to the same value.
 */
@property (nonatomic, unsafe_unretained) BOOL audio;
/**
 @brief enable/disable video.
 @discussion Default value is NO. This is a convinience property to set both sendVideo and receiveVideo to the same value.
 */
@property (nonatomic, unsafe_unretained) BOOL video;
/**
 @brief enable/disable sending audio.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL sendAudio;
/**
 @brief enable/disable sending audio.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL receiveAudio;
/**
 @brief enable/disable sending video.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL sendVideo;
/**
 @brief enable/disable receiving video.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL receiveVideo;
/**
 @brief enable/disable dataChannel.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL dataChannel;
/**
 @brief enable/disable file transfer.
 @discussion Default value is NO.
 */
@property (nonatomic, unsafe_unretained) BOOL fileTransfer;
/**
 @brief number of seconds for file transfer timeout.
 @discussion Default value is 60.
 */
@property (nonatomic, unsafe_unretained) NSInteger timeout;
/**
 @brief Used to limit remote peers audio media bitrate.
 @discussion Default value is 0, meaning not bitrate limit.
 */
@property (nonatomic, unsafe_unretained) NSInteger maxAudioBitrate;
/**
 @brief Used to limit remote peers video media bitrate.
 @discussion Default value is 512.
 */
@property (nonatomic, unsafe_unretained) NSInteger maxVideoBitrate;
/**
 @brief Used to limit remote peers data bitrate.
 @discussion Default value is 0, meaning not bitrate limit.
 */
@property (nonatomic, unsafe_unretained) NSInteger maxDataBitrate;
/*!
 * @brief Optional configuration for advanced users.
 * @discussion The userInfo dictionnary key and associated settings are:
 * @"STUN" key (NSNumber value): set @"STUN" to @YES to DISABLE STUN server.
 * @"TURN" key (NSNumber value): set @"TURN" to @YES to DISABLE TURN server.
 * @"disableHOST" key, set @YES to disable HOST.
 * @"transport" key (NSString value): expected values are @"TCP" or @"UDP".
 * @"audio" key (NSString value): preferred audio codec, expected values are @"Opus" or @"iLBC".
 * @param userInfo NSDictionary carrying the desired settings. Read the discussion for details.
 * @deprecated Use -(BOOL)advancedSetting:(NSString *)settingKey setValue:(id)value instead.
 */
@property (nonatomic, weak) NSDictionary *userInfo DEPRECATED_MSG_ATTRIBUTE("Use -(BOOL)advancedSetting:(NSString *)settingKey setValue:(id)value instead.");

/*!
 * @brief Optional configuration for advanced users.
 * @discussion The settingKey and associated settings values are:
 * @"STUN" key, (NSNumber value): set @"disableSTUN" to @YES to disable STUN server.
 * @"TURN" key, (NSNumber value): set @"disableTURN" to @YES to disable TURN server.
 * @"disableHOST" key, set @YES to disable HOST.
 * @"transport" key, (NSString value): expected values are @"TCP" or @"UDP".
 * @"audio" key, (NSString value): preferred audio codec, expected values are @"Opus" or @"iLBC".
 * @"startWithBackCamera" key, (NSNumber value): if you send the camera, this will determine the local camera to start the video capture. Default is @NO (ie: use front camera)
 * @"preferedCaptureSessionPresets" key, (NSArray value): ordered array of AVCaptureSessionPreset for the video capture, the first if any that can be used for the device will be picked.
 * @return YES if the setting was sucessfully set (valid setting key and associated value).
 */
-(BOOL)advancedSettingKey:(NSString *)settingKey setValue:(id)settingValue;


@end

/**
 @brief The class representing the connection to the room.
 @discussion You should make sure this objects does not get released as long as you need it, for example by storing it as a strong property.
 */
@interface SKYLINKConnection : NSObject

/**
 @name Delegates
 */

/**
 @brief delegate related to life cycle, implementing the SKYLINKConnectionLifeCycleDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionLifeCycleDelegate> lifeCycleDelegate;
/**
 @brief delegate related to remote peer activities, implementing the SKYLINKConnectionRemotePeerDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionRemotePeerDelegate> remotePeerDelegate;
/**
 @brief delegate related to audio/video media, implementing the SKYLINKConnectionMediaDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionMediaDelegate> mediaDelegate;
/**
 @brief delegate related to various type of custom messages, implementing the SKYLINKConnectionMessagesDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionMessagesDelegate> messagesDelegate;
/**
 @brief delegate related to file transfer, implementing the SKYLINKConnectionFileTransferDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionFileTransferDelegate> fileTransferDelegate;
/**
 @brief delegate related to room recording, implementing the SKYLINKConnectionRecordingDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionRecordingDelegate> recordingDelegate;
/**
 @brief delegate related to stats providing, implementing the SkylinkStatsDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionStatsDelegate> statsDelegate;

/**
 @name Peer Id
 */

/**
 @brief peer id of the current local user
 */
@property(nonatomic, readonly) NSString *myPeerId;

/*!
 * @brief Maximun number of peers.
 * @discussion The default value depends on the configuration.
 */
@property(nonatomic, assign) NSInteger maxPeerCount;

/**
 @name Lifecycle
 */

/**
 @brief Initialize and return a newly allocated connection object.
 @discussion Changes in config after creating the object won't affect the connection.
 @param config The connection configuration object.
 @param appKey APP key.
 */
- (id)initWithConfig:(SKYLINKConnectionConfig*)config appKey:(NSString*)appKey;

/**
 @brief Join the room specifiying the shared secret, room name and user info.
 @discussion It is recommended to use connectToRoomWithCredentials:roomName:userInfo: after calculating the credentials on a server, but if the client application has no server implementation then this one should be used.
 @param secret Shared secret.
 @param roomName Name of the room to join.
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return NO if a connection is already established.
 */
- (BOOL)connectToRoomWithSecret:(NSString*)secret roomName:(NSString*)roomName userInfo:(id)userInfo;

/**
 @brief Join the room specifiying the calculated credential info, room name and user info.
 @discussion The dictionary 'credInfo' is expected to have 3 non-Null parameters: an NSString type 'credential', an NSDate type 'startTime' and an NSNumber type 'duration' in hours. The 'startTime' must be a correct time of the client application's timezone. Both the 'startTime' and 'duration' must be the same as the ones that were used to calculate the credential. Failing to provide any of them will result in a connection denial.
 @param credInfo A dictionary containing a credential, startTime and duration.
 @param roomName Name of the room to join.
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return nil if connection can be established otherwise a message specifying reason for connection denial.
 */
- (NSString*)connectToRoomWithCredentials:(NSDictionary*)credInfo roomName:(NSString*)roomName userInfo:(id)userInfo;

/**
 @brief Join the room specifiying the calculated string URL and user info.
 @discussion Use this method when you calculate the URL on your server with your API key, secret and room name. Allows you to avoid having those parameters in the iOS app code.
 @param stringURL Generated with room name, appKey, secret, startTime and duration. Typed NSString (not NSURL).
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return YES (success) if connection can be established. NO if a connection is already established.
 */
- (BOOL)connectToRoomWithStringURL:(NSString *)stringURL userInfo:(id)userInfo;

/**
 @brief Leave the room.
 @discussion Leave the room and remove any video renderers and PeerConnections.
 @param completion The completion block called on the UI thread after leaving the room. This block is a good place to deallocate SKYLINKConnection if desired. Leave as empty block if not required.
 */
- (void)disconnect:(void (^) ())completion;

/**
 @name Room Control.
 */

/**
 @brief Refresh peer connection with a specified peer.
 @discussion This method is provided as a convenience method. So that one can call if a peer streams are not behaving correctly.
 @param peerId The unique id of the peer with whom the connection is being refreshed.
 */
- (void)refreshConnection:(NSString*)peerId;

/**
 @brief Lock the room.
 */
- (void)lockTheRoom;

/**
 @brief Unlock the room.
 */
- (void)unlockTheRoom;

/**
 @name Media
 */

/**
 @brief Mute/unmute own audio and trigger mute/unmute audio call back for all other peers.
 @param isMuted Flag to set if audio should be muted. Set to true to mute and false to unmute.
 */
- (void)muteAudio:(BOOL)isMuted;

/**
 @brief Mute/unmute own video and trigger mute/unmute video call back for all other peers.
 @param isMuted Flag to set if video should be muted. Set to true to mute and false to unmute.
 */
- (void)muteVideo:(BOOL)isMuted;

/**
 @brief Checks if own audio is currently muted.
 @return true if audio is muted and false otherwise.
 */
- (BOOL)isAudioMuted;

/**
 @brief Checks if own video is currently muted.
 @return true if video is muted and false otherwise.
 */
- (BOOL)isVideoMuted;

/**
 @brief Switches between front and back camera. By default the front camera input is captured.
 */
- (void)switchCamera;

/**
 @name Recording (Beta)
 */

/**
 @brief Start the recording of the room.
 @warning This feature is in BETA.
 @discussion This is a Skylink Media Relay only feature, it needs to be enable for the API Key in Temasys developer console.
 @return The NSString return value is an error description. A nil value means no error occured.
 */
- (NSString *)startRecording;

/**
 @brief Stop the recording of the room.
 @warning This feature is in BETA.
 @discussion This is a Skylink Media Relay only feature, it needs to be enable for the API Key in Temasys developer console.
 @return The NSString return value is an error description. A nil value means no error occured.
 */
- (NSString *)stopRecording;

/**
 @name Messaging
 */

/**
 @brief Send a custom message (dictionary, array or string) to a peer via signaling server.
 @discussion If the 'peerId' is not given then the message is broadcasted to all the peers.
 @param message User defined message to be sent. May be an NSString, NSDictionary or NSArray.
 @param peerId The unique id of the peer to whom the message is sent.
 */
- (void)sendCustomMessage:(id)message peerId:(NSString*)peerId;

/**
 @brief Send a message (dictionary, array or string) to a peer via data channel.
 @discussion If the 'peerId' is not given then the message is broadcasted to all the peers.
 @param message User defined message to be sent. May be an NSString, NSDictionary, NSArray.
 @param peerId The unique id of the peer to whom the message is sent.
 @return YES if the message has been succesfully sent to all targeted peers, if NO is returned and verbose is enabled then informations will be logged.
 */
- (BOOL)sendDCMessage:(id)message peerId:(NSString*)peerId;

/**
 @brief Send binary data to a peer via data channel.
 @discussion If the 'peerId' is not given then the data is sent to all the peers. If the caller passes data object exceeding the maximum length i.e. 65456, excess bytes are truncated to the limit before sending the data on to the channel.
 @param data Binary data to be sent to the peer. The maximum size the method expects is 65456 bytes.
 @param peerId The unique id of the peer to whom the data is sent.
 */
- (void)sendBinaryData:(NSData*)data peerId:(NSString*)peerId;

/**
 @name File Transfer
 */

/**
 @brief This will trigger a file permission event at a peer.
 @param fileURL The url of the file to send.
 @param assetType The type of the asset to send.
 @param peerId The unique id of the peer to whom the file would be sent.
 @exception exception An exception will be raised if there is already a file transfer being done with the same peer.
 */
- (void)sendFileTransferRequest:(NSURL*)fileURL assetType:(SKYLINKAssetType)assetType peerId:(NSString*)peerId;

/**
 @brief This will trigger a broadcast file permission event at all peers in the room.
 @discussion If all the data channel connections are busy in some file transfer then this message will be ignored. If one or more data channel connections are not busy in some file transfer then this will trigger a broadcast file permission event at the available peers.
 @param fileURL The url of the file to send.
 @param assetType The type of the asset to send.
 */
- (void)sendFileTransferRequest:(NSURL*)fileURL assetType:(SKYLINKAssetType)assetType;

/**
 @brief Accept or reject the file transfer request from a peer.
 @param accept Flag to specify whether the request is accepted.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer who sent the file transfer request.
 */
- (void)acceptFileTransfer:(BOOL)accept filename:(NSString*)filename peerId:(NSString*)peerId;

/**
 @brief Cancel the existing on going transfer at anytime.
 @param filename The name of the file in request (optional).
 @param peerId The unique id of the peer with whom file is being transmitted.
 */
- (void)cancelFileTransfer:(NSString*)filename peerId:(NSString*)peerId;

/**
 @name Miscellaneous
 */

/**
 @brief Update user information for every other peer and triggers user info call back at all the other peer's end.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 */
- (void)sendUserInfo:(id)userInfo;

/**
 @brief Get the cached user info for a particular peer.
 @param peerId The unique id of the peer.
 @return User defined information. May be an NSString, NSDictionary or NSArray.
 */
- (id)getUserInfo:(NSString*)peerId;

/**
 @brief Get webRTC stats.
 @warning This feature is in BETA.
 @param peerId the peerId for which connection you want the stats
 @param mediaDirection used to specify whether you want upload or download stats, or both (Both:0, mediaSent: 1, mediaReceived: 2).
 @discussion Stats are returned within the SKYLINKConnectionStatsDelegate
 */
- (void)getWebRTCStatsForPeerId:(NSString *)peerId mediaDirection:(int)mediaDirection;

/**
 @brief Get room ID.
 @return Room ID.
 @discussion This is generally not needed.
 */
- (NSString *)roomId;


/**
 @name Utility
 */

/**
 @brief Get the version string of this Skylink SDK for iOS.
 @return Version string of this Skylink SDK for iOS.
 */
+ (NSString*)getSkylinkVersion;

/*!
 * @brief Enable/disable verbose logs for all the connections.
 * @warning You should always disable logs in RELEASE mode.
 * @param verbose enable/disable verbose logs. Default is NO.
 */
+ (void)setVerbose:(BOOL)verbose;


/**
 @brief Calculate credentials to be used by the connection.
 @param roomName Name of the room.
 @param duration Duration of the call in hours.
 @param startTime Start time of the call as per client application time zone.
 @param secret The shared secret.
 @return The calculated credential string.
 */
+ (NSString*)calculateCredentials:(NSString*)roomName duration:(NSNumber*)duration startTime:(NSDate*)startTime secret:(NSString*)secret;

@end
