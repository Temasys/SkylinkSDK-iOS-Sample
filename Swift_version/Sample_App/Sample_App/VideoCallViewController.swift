//
//  VideoCallViewController.swift
//  Sample_App
//
//  Created by Phyo Pwint  on 6/4/16.
//  Copyright © 2016 Temasys . All rights reserved.
//

import UIKit
import AVFoundation

class VideoCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate {
    
    var peerVideoSize: CGSize!
    var peerVideoView: UIView!
    var topView: UIView!
    let ROOM_NAME = "VIDEO-CALL-ROOM"
    
    var skylinkConnection: SKYLINKConnection!
    var remotePeerId: NSString!
    var skylinkApiKey: String!
    var skylinkApiSecret: NSString!
    
    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var remotePeerVideoContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnAudioTap: UIButton!
    @IBOutlet weak var btnVideoTap: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("SKYLINKConnection version = %@", SKYLINKConnection.getSkylinkVersion())
        self.title = "1-1 Video Call"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel.png"), style: .Plain, target: self, action: #selector(VideoCallViewController.disConnect))
        let infoButton: UIButton = UIButton(type: .InfoLight)
        infoButton.addTarget(self, action: #selector(VideoCallViewController.showInfo), forControlEvents: .TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        //Creating configuration
        let config:SKYLINKConnectionConfig = SKYLINKConnectionConfig()
        config.video = true
        config.audio = true
        // Creating SKYLINKConnection
        self.skylinkConnection = SKYLINKConnection(config: config, appKey: self.skylinkApiKey! as String)
        self.skylinkConnection.lifeCycleDelegate = self
        self.skylinkConnection.mediaDelegate = self
        self.skylinkConnection.remotePeerDelegate = self
        
        // Connecting to a room
        SKYLINKConnection.setVerbose(true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), {() -> Void in
            self.skylinkConnection.connectToRoomWithSecret(self.skylinkApiSecret! as String, roomName: self.ROOM_NAME, userInfo: nil)
        })
        
        //Disable Btn
        btnAudioTap.enabled = false
        refreshButton.enabled = false
        btnVideoTap.enabled = false
        btnFlipCamera.enabled = false
    }
    
    func disConnect() {
        self.activityIndicator.startAnimating()
        self.skylinkConnection.unlockTheRoom()
        if (self.skylinkConnection != nil) {
            self.skylinkConnection.disconnect({() -> Void in
                self.activityIndicator.stopAnimating()
                self.navigationController!.popViewControllerAnimated(true)
            })
        }
    }
    
    func showInfo() {
        let msgTitle: String = "Infos"
        let msg: String = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(self.skylinkConnection.myPeerId)\n\nKey: •••••\(self.skylinkApiKey.substringFromIndex(self.skylinkApiKey.startIndex.advancedBy(self.skylinkApiKey.characters.count-7)))\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        AlertMessage(msgTitle, msg:msg)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if (self.peerVideoView != nil) {
            self.peerVideoView.frame = self.aspectFillRectForSize(self.peerVideoSize, containedInRect: self.remotePeerVideoContainerView.frame)
        }
    }
    
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    
    func connection(connection: SKYLINKConnection, didConnectWithMessage errorMessage: String, success isSuccess: Bool) {
        if isSuccess {
            NSLog("Inside %@", #function)
        }
        else {
            let msgTitle: String = "Connection failed"
            let msg: String = errorMessage
            AlertMessage(msgTitle, msg:msg)
            self.navigationController!.popViewControllerAnimated(true)
        }
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            self.activityIndicator.stopAnimating()
            //Enable Btn
            self.btnAudioTap.enabled = true
            self.btnVideoTap.enabled = true
            self.refreshButton.enabled = true
            self.btnFlipCamera.enabled = true
        })
    }
    
    func connection(connection: SKYLINKConnection, didRenderUserVideo userVideoView: UIView) {
        self.addRenderedVideo(userVideoView, insideContainer: self.localVideoContainerView, mirror: true)
    }
    
    func connection(connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String) {
        
        let alertController = UIAlertController(title: "Disconnected" , message: errorMessage, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: {
            self.disConnect()
        })
        
    }
    
    // MARK:  - SKYLINKConnectionRemotePeerDelegate
    
    func connection(connection: SKYLINKConnection, didJoinPeer userInfo: AnyObject, mediaProperties pmProperties: SKYLINKPeerMediaProperties, peerId: String) {
        self.activityIndicator.stopAnimating()
        self.remotePeerId = peerId
    }
    
    func connection(connection: SKYLINKConnection, didRenderPeerVideo peerVideoView: UIView, peerId: String) {
        self.addRenderedVideo(peerVideoView, insideContainer: self.remotePeerVideoContainerView, mirror: false)
    }
    
    func connection(connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String, peerId: String) {
        self.remotePeerId = nil
        self.skylinkConnection.unlockTheRoom()
        AlertMessage("Peer Left", msg: "\nPeer ID:\(peerId)\n has been left")
    }
    
    // MARK: - SKYLINKConnectionMediaDelegate
    
    func connection(connection: SKYLINKConnection, didChangeVideoSize videoSize: CGSize, videoView: UIView) {
        if videoSize.height > 0 && videoSize.width > 0 {
            var correspondingContainerView: UIView
            if videoView.isDescendantOfView(self.localVideoContainerView) {
                correspondingContainerView = self.localVideoContainerView
            }
            else {
                correspondingContainerView = self.remotePeerVideoContainerView
                self.peerVideoView = videoView
                self.peerVideoSize = videoSize
            }
            videoView.frame = self.aspectFillRectForSize(videoSize, containedInRect: correspondingContainerView.frame)
            self.viewWillLayoutSubviews()
            // for aspect fit, use AVMakeRectWithAspectRatioInsideRect(videoSize, correspondingContainerView.bounds);
        }
    }
    
    // MARK: - Other
    
    // for didRender.. Delegates
    func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView, mirror shouldMirror: Bool) {
        videoView.frame = containerView.bounds
        for subview: UIView in containerView.subviews {
            subview.removeFromSuperview()
        }
        containerView.insertSubview(videoView, atIndex: 0)
    }
    
    func aspectFillRectForSize(insideSize: CGSize, containedInRect containerRect: CGRect) -> CGRect {
        let maxFloat: CGFloat = max(containerRect.size.height, containerRect.size.width)
        let aspectRatio: CGFloat = insideSize.width / insideSize.height
        var frame: CGRect = CGRectMake(0, 0, containerRect.size.width, containerRect.size.height)
        if insideSize.width < insideSize.height {
            frame.size.width = maxFloat
            frame.size.height = frame.size.width / aspectRatio
        }
        else {
            frame.size.height = maxFloat;
            frame.size.width = frame.size.height * aspectRatio;
        }
        frame.origin.x = (containerRect.size.width - frame.size.width) / 2;
        frame.origin.y = (containerRect.size.height - frame.size.height) / 2;
        return frame
    }
    
    func AlertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true) {
        }
    }
    
    // MARK: IBAction TouchUp
    @IBAction func toogleVideoTap(sender: AnyObject) {
        self.skylinkConnection.muteVideo(!self.skylinkConnection.isVideoMuted())
        sender.setImage(UIImage(named: ((self.skylinkConnection.isVideoMuted()) ? "NoVideoFilled.png" : "VideoCall.png")), forState: .Normal)
        self.localVideoContainerView.hidden = self.skylinkConnection.isVideoMuted()
    }
    
    @IBAction func toogleSoundTap(sender: AnyObject) {
        self.skylinkConnection.muteAudio(!self.skylinkConnection.isAudioMuted())
        sender.setImage(UIImage(named: ((self.skylinkConnection.isAudioMuted()) ? "NoMicrophoneFilled.png" : "Microphone.png")), forState: .Normal)
    }
    
    @IBAction func switchCameraTap(sender: AnyObject) {
        self.skylinkConnection.switchCamera()
    }
    
    @IBAction func refreshTap(sender: AnyObject) {
        if (self.remotePeerId != nil) {
            self.activityIndicator.startAnimating()
            self.skylinkConnection.unlockTheRoom()
            self.skylinkConnection.refreshConnection(self.remotePeerId! as String)
        }
        else {
            let msgTitle: String = "No peer connexion to refresh"
            let msg: String = "Tap this button to refresh the peer connexion if needed."
            AlertMessage(msgTitle, msg:msg)
        }
    }
    
}
