//
//  TEMAConnectionManager.h
//
//  Created by Temasys.
//  Copyright (c) 2015 TemaSys. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

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

extern NSString * _Nonnull const SKYLINKRequiresPermissionNotification;

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
- (void)connection:(nonnull SKYLINKConnection *)connection didConnectWithMessage:(null_unspecified NSString *)errorMessage success:(BOOL)isSuccess;

/**
 @brief Called upon successful capturing and rendering of the local front camera.
 @param connection The underlying connection object.
 @param userVideoView The video view of the connecting client.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didRenderUserVideo:(null_unspecified UIView *)userVideoView;

/**
 @brief Called when a remote peer locks/unlocks the room.
 @param connection The underlying connection object.
 @param lockStatus The status of the lock.
 @param peerId The unique id of the peer who originated the action.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didLockTheRoom:(BOOL)lockStatus peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called when a warning is received from the underlying system.
 @param connection The underlying connection object.
 @param message Warning message from the underlying system.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveWarning:(null_unspecified NSString *)message;

/**
 @brief Called when the client is disconnected from the server.
 @param connection The underlying connection object.
 @param errorMessage Message specifying the reason of disconnection.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didDisconnectWithMessage:(null_unspecified NSString *)errorMessage;

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
- (void)connection:(nonnull SKYLINKConnection *)connection didJoinPeer:(null_unspecified id)userInfo mediaProperties:(null_unspecified SKYLINKPeerMediaProperties *)pmProperties peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon receiving a remote video stream.
 @param connection The underlying connection object.
 @param peerVideoView The video view of the joining peer.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didRenderPeerVideo:(null_unspecified UIView *)peerVideoView peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon receiving an update about a user info.
 @param connection The underlying connection object.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveUserInfo:(null_unspecified id)userInfo peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called when a peer has left the room implictly or explicitly.
 @param connection The underlying connection object.
 @param errorMessage Error message in case the peer is left due to some error.
 @param peerId The unique id of the leaving peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didLeavePeerWithMessage:(null_unspecified NSString *)errorMessage peerId:(null_unspecified NSString *)peerId;

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
- (void)connection:(nonnull SKYLINKConnection *)connection didChangeVideoSize:(CGSize)videoSize videoView:(null_unspecified UIView *)videoView;

/**
 @brief Called when a peer mutes/unmutes its audio.
 @param connection The underlying connection object.
 @param isMuted Flag to specify whether the audio is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didToggleAudio:(BOOL)isMuted peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called when a peer mutes/unmutes its video.
 @param connection The underlying connection object.
 @param isMuted Flat to specify whether the video is muted.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didToggleVideo:(BOOL)isMuted peerId:(null_unspecified NSString *)peerId;

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
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveCustomMessage:(null_unspecified id)message public:(BOOL)isPublic peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon receiving a data channel chat message.
 @param connection The underlying connection object.
 @param message User defined message. May be an NSString, NSDictionary or NSArray.
 @param isPublic Flag to specify whether the message was a broadcast.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveDCMessage:(null_unspecified id)message public:(BOOL)isPublic peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon receiving binary data on data channel.
 @param connection The underlying connection object.
 @param data Binary data.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveBinaryData:(null_unspecified NSData *)data peerId:(null_unspecified NSString *)peerId;

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
- (void)connection:(nonnull SKYLINKConnection *)connection didReceiveRequest:(null_unspecified NSString *)filename peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon receiving a file transfer permission from a peer.
 @param connection The underlying connection object.
 @param isPermitted Flag to specify whether the request was accepted.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didReceivePermission:(BOOL)isPermitted filename:(null_unspecified NSString *)filename peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called when the file being transferred is halted.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param message The message specifying reason for the file transfer drop.
 @param isExplicit Flag to specify whether the transfer was halted explicity by the sender.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didDropTransfer:(null_unspecified NSString *)filename reason:(null_unspecified NSString *)message isExplicit:(BOOL)isExplicit peerId:(null_unspecified NSString *)peerId;

/**
 @brief Called upon every file transfer progress update.
 @param connection The underlying connection object.
 @param percentage The perccentage representing the progress of the transfer (CGFloat from 0 to 1).
 @param isOutgoing Boolean to specify if the transfer is a file beign sent (value would be YES) or received (value would be NO).
 @param filename The name of the file in transmission.
 @param peerId The unique id of the peer thie file is sent to or received from.
 @discussion Alternatively, if many of your objects need to get these informations, it can register to the notification with identifier: @"SKYLINKFileProgress".
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didUpdateProgress:(CGFloat)percentage isOutgoing:(BOOL)isOutgoing filename:(null_unspecified NSString *)filename peerId:(null_unspecified NSString *)peerId;


/**
 @brief Called upon file transfer completion.
 @param connection The underlying connection object.
 @param filename The name of the file in request.
 @param fileData NSData object holding the data transferred.
 @param peerId The unique id of the peer.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection didCompleteTransfer:(null_unspecified NSString *)filename fileData:(null_unspecified NSData *)fileData peerId:(null_unspecified NSString *)peerId;

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
- (void)connection:(nonnull SKYLINKConnection *)connection recordingDidStartWithID:(null_unspecified NSString *)recordingID;

/**
 @brief Called upon recording stop event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingID The id of the recording.
 @discussion This will be triggered after you call stopRecording successfully or if the backend notifies of recording stoped.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection recordingDidStopWithID:(null_unspecified NSString *)recordingID;
/**
 @brief Called upon recording error event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingID The id of the recording (might be nil if unknown).
 @param errorMessage The error description as a string.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection recording:(null_unspecified NSString *)recordingID didError:(null_unspecified NSString *)errorMessage;
/**
 @brief Called upon recording completion event.
 @warning This feature is in BETA.
 @param connection The underlying connection object.
 @param recordingId The id of the recording.
 @param videoLink The mixing recording URL as a string.
 @param peerId The peerId who's recording the link is for. If nil then the URL is a mixin recording link.
 @discussion For this to be called you need to make sure the app key used is configured for recording.
 */
- (void)connection:(nonnull SKYLINKConnection *)connection recordingVideoLink:(null_unspecified NSString *)videoLink peerId:(null_unspecified NSString *)peerId recordingId:(null_unspecified NSString *)recordingId;

@end


/**
 @brief Class representing the handshaking peer properties.
 @discussion This class is used in the delegate method called when a peer joins the room to carry informations about the joining peer media properties.
 */
@interface SKYLINKPeerMediaProperties : NSObject

/**
 @brief whether the peer has audio.
 */
@property (nonatomic, assign) BOOL hasAudio;
/**
 @brief is audio stereo.
 @discussion if 'hasAudio' returns false then this property is insignificant.
 */
@property (nonatomic, assign) BOOL isAudioStereo;
/**
 @brief is audio muted.
 @discussion if 'hasAudio' returns false then this property is insignificant.
 */
@property (nonatomic, assign) BOOL isAudioMuted;
/**
 @brief whether the peer has video 
 */
@property (nonatomic, assign) BOOL hasVideo;
/**
 @brief is video muted.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, assign) BOOL isVideoMuted;
/**
 @brief width of the video frame.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, assign) NSInteger videoWidth;
/**
 @brief height of the video frame.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, assign) NSInteger videoHeight;
/**
 @brief frame rate of the video.
 @discussion if 'hasVideo' returns false then this property is insignificant.
 */
@property (nonatomic, assign) NSInteger videoFrameRate;

@end

/**
 @discussion The class representing the conversation configuration.
 */
@interface SKYLINKConnectionConfig : NSObject

/**
 @brief enable/disable audio.
 @discussion Default value is NO. This is a convinience property to set both sendAudio and receiveAudio to the same value.
 */
@property (nonatomic, assign) BOOL audio;
/**
 @brief enable/disable video.
 @discussion Default value is NO. This is a convinience property to set both sendVideo and receiveVideo to the same value.
 */
@property (nonatomic, assign) BOOL video;
/**
 @brief enable/disable sending audio.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL sendAudio;
/**
 @brief enable/disable sending audio.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL receiveAudio;
/**
 @brief enable/disable sending video.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL sendVideo;
/**
 @brief enable/disable receiving video.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL receiveVideo;
/**
 @brief enable/disable dataChannel.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL dataChannel;
/**
 @brief enable/disable file transfer.
 @discussion Default value is NO.
 */
@property (nonatomic, assign) BOOL fileTransfer;
/**
 @brief number of seconds for file transfer timeout.
 @discussion Default value is 60.
 */
@property (nonatomic, assign) NSInteger timeout;
/**
 @brief Used to limit remote peers audio media bitrate.
 @discussion Default value is 0, meaning not bitrate limit.
 */
@property (nonatomic, assign) NSInteger maxAudioBitrate;
/**
 @brief Used to limit remote peers video media bitrate.
 @discussion Default value is 512.
 */
@property (nonatomic, assign) NSInteger maxVideoBitrate;
/**
 @brief Used to limit remote peers data bitrate.
 @discussion Default value is 0, meaning not bitrate limit.
 */
@property (nonatomic, assign) NSInteger maxDataBitrate;
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
@property (nonatomic, weak) NSDictionary * _Null_unspecified userInfo DEPRECATED_MSG_ATTRIBUTE("Use -(BOOL)advancedSetting:(NSString *)settingKey setValue:(id)value instead.");

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
-(BOOL)advancedSettingKey:(null_unspecified NSString *)settingKey setValue:(null_unspecified id)settingValue;


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
@property(nonatomic, weak) id<SKYLINKConnectionLifeCycleDelegate> _Null_unspecified lifeCycleDelegate;
/**
 @brief delegate related to remote peer activities, implementing the SKYLINKConnectionRemotePeerDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionRemotePeerDelegate> _Null_unspecified remotePeerDelegate;
/**
 @brief delegate related to audio/video media, implementing the SKYLINKConnectionMediaDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionMediaDelegate> _Null_unspecified mediaDelegate;
/**
 @brief delegate related to various type of custom messages, implementing the SKYLINKConnectionMessagesDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionMessagesDelegate> _Null_unspecified messagesDelegate;
/**
 @brief delegate related to file transfer, implementing the SKYLINKConnectionFileTransferDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionFileTransferDelegate> _Null_unspecified fileTransferDelegate;
/**
 @brief delegate related to room recording, implementing the SKYLINKConnectionRecordingDelegate protocol.
 */
@property(nonatomic, weak) id<SKYLINKConnectionRecordingDelegate> _Null_unspecified recordingDelegate;

/**
 @name Peer Id
 */

/**
 @brief peer id of the current local user
 */
@property(nonatomic, readonly) NSString * _Null_unspecified myPeerId;

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
- (null_unspecified id)initWithConfig:(null_unspecified SKYLINKConnectionConfig *)config appKey:(null_unspecified NSString *)appKey;

/**
 @brief Join the room specifiying the shared secret, room name and user info.
 @discussion It is recommended to use connectToRoomWithCredentials:roomName:userInfo: after calculating the credentials on a server, but if the client application has no server implementation then this one should be used.
 @param secret Shared secret.
 @param roomName Name of the room to join.
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return NO if a connection is already established.
 */
- (BOOL)connectToRoomWithSecret:(null_unspecified NSString *)secret roomName:(null_unspecified NSString *)roomName userInfo:(null_unspecified id)userInfo;

/**
 @brief Join the room specifiying the calculated credential info, room name and user info.
 @discussion The dictionary 'credInfo' is expected to have 3 non-Null parameters: an NSString type 'credential', an NSDate type 'startTime' and an NSNumber type 'duration' in hours. The 'startTime' must be a correct time of the client application's timezone. Both the 'startTime' and 'duration' must be the same as the ones that were used to calculate the credential. Failing to provide any of them will result in a connection denial.
 @param credInfo A dictionary containing a credential, startTime and duration.
 @param roomName Name of the room to join.
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return nil if connection can be established otherwise a message specifying reason for connection denial.
 */
- (nonnull NSString *)connectToRoomWithCredentials:(null_unspecified NSDictionary *)credInfo roomName:(null_unspecified NSString *)roomName userInfo:(null_unspecified id)userInfo;

/**
 @brief Join the room specifiying the calculated string URL and user info.
 @discussion Use this method when you calculate the URL on your server with your API key, secret and room name. Allows you to avoid having those parameters in the iOS app code.
 @param stringURL Generated with room name, appKey, secret, startTime and duration. Typed NSString (not NSURL).
 @param userInfo User defined information (relating to oneself). May be an NSString, NSDictionary or NSArray.
 @return YES (success) if connection can be established. NO if a connection is already established.
 */
- (BOOL)connectToRoomWithStringURL:(null_unspecified NSString *)stringURL userInfo:(null_unspecified id)userInfo;

/**
 @brief Leave the room.
 @discussion Leave the room and remove any video renderers and PeerConnections.
 @param completion The completion block called on the UI thread after leaving the room. This block is a good place to deallocate SKYLINKConnection if desired. Leave as empty block if not required.
 */
- (void)disconnect:(void (^_Null_unspecified) (void))completion;

/**
 @name Room Control.
 */

/**
 @brief Refresh peer connection with a specified peer.
 @discussion This method is provided as a convenience method. So that one can call if a peer streams are not behaving correctly.
 @param peerId The unique id of the peer with whom the connection is being refreshed.
 */
- (void)refreshConnection:(null_unspecified NSString *)peerId;

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
- (nullable NSString *)startRecording;

/**
 @brief Stop the recording of the room.
 @warning This feature is in BETA.
 @discussion This is a Skylink Media Relay only feature, it needs to be enable for the API Key in Temasys developer console.
 @return The NSString return value is an error description. A nil value means no error occured.
 */
- (nullable NSString *)stopRecording;

/**
 @name Messaging
 */

/**
 @brief Send a custom message (dictionary, array or string) to a peer via signaling server.
 @discussion If the 'peerId' is not given then the message is broadcasted to all the peers.
 @param message User defined message to be sent. May be an NSString, NSDictionary or NSArray.
 @param peerId The unique id of the peer to whom the message is sent.
 */
- (void)sendCustomMessage:(null_unspecified id)message peerId:(null_unspecified NSString *)peerId;

/**
 @brief Send a message (dictionary, array or string) to a peer via data channel.
 @discussion If the 'peerId' is not given then the message is broadcasted to all the peers.
 @param message User defined message to be sent. May be an NSString, NSDictionary, NSArray.
 @param peerId The unique id of the peer to whom the message is sent.
 @return YES if the message has been succesfully sent to all targeted peers, if NO is returned and verbose is enabled then informations will be logged.
 */
- (BOOL)sendDCMessage:(null_unspecified id)message peerId:(null_unspecified NSString *)peerId;

/**
 @brief Send binary data to a peer via data channel.
 @discussion If the 'peerId' is not given then the data is sent to all the peers. If the caller passes data object exceeding the maximum length i.e. 65456, excess bytes are truncated to the limit before sending the data on to the channel.
 @param data Binary data to be sent to the peer. The maximum size the method expects is 65456 bytes.
 @param peerId The unique id of the peer to whom the data is sent.
 */
- (void)sendBinaryData:(null_unspecified NSData *)data peerId:(null_unspecified NSString *)peerId;

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
- (void)sendFileTransferRequest:(null_unspecified NSURL *)fileURL assetType:(SKYLINKAssetType)assetType peerId:(null_unspecified NSString *)peerId;

/**
 @brief This will trigger a broadcast file permission event at all peers in the room.
 @discussion If all the data channel connections are busy in some file transfer then this message will be ignored. If one or more data channel connections are not busy in some file transfer then this will trigger a broadcast file permission event at the available peers.
 @param fileURL The url of the file to send.
 @param assetType The type of the asset to send.
 */
- (void)sendFileTransferRequest:(null_unspecified NSURL *)fileURL assetType:(SKYLINKAssetType)assetType;

/**
 @brief Accept or reject the file transfer request from a peer.
 @param accept Flag to specify whether the request is accepted.
 @param filename The name of the file in request.
 @param peerId The unique id of the peer who sent the file transfer request.
 */
- (void)acceptFileTransfer:(BOOL)accept filename:(null_unspecified NSString *)filename peerId:(null_unspecified NSString *)peerId;

/**
 @brief Cancel the existing on going transfer at anytime.
 @param filename The name of the file in request (optional).
 @param peerId The unique id of the peer with whom file is being transmitted.
 */
- (void)cancelFileTransfer:(null_unspecified NSString *)filename peerId:(null_unspecified NSString *)peerId;

/**
 @name Miscellaneous
 */

/**
 @brief Update user information for every other peer and triggers user info call back at all the other peer's end.
 @param userInfo User defined information. May be an NSString, NSDictionary or NSArray.
 */
- (void)sendUserInfo:(null_unspecified id)userInfo;

/**
 @brief Get the cached user info for a particular peer.
 @param peerId The unique id of the peer.
 @return User defined information. May be an NSString, NSDictionary or NSArray.
 */
- (nonnull id)getUserInfo:(null_unspecified NSString *)peerId;


/**
 @brief Get room ID.
 @return Room ID.
 @discussion This is generally not needed.
 */
- (nonnull NSString *)roomId;


/**
 @name Utility
 */

/**
 @brief Get the version string of this Skylink SDK for iOS.
 @return Version string of this Skylink SDK for iOS.
 */
+ (nonnull NSString *)getSkylinkVersion;

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
+ (nonnull NSString *)calculateCredentials:(null_unspecified NSString *)roomName duration:(null_unspecified NSNumber *)duration startTime:(null_unspecified NSDate *)startTime secret:(null_unspecified NSString *)secret;

@end
