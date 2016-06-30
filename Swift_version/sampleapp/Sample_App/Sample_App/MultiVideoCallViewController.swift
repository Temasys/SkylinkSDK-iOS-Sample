//
//  MultiVideoCallViewController.swift
//  Sample_App
//
//  Created by Phyo Pwint  on 7/4/16.
//  Copyright © 2016 Temasys . All rights reserved.
//

import UIKit
import AVFoundation


class MultiVideoCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate {
    
    var skylinkConnection: SKYLINKConnection!
    var peerIds = [String]()
    var peersInfos : NSMutableDictionary!
    var skylinkApiKey: String!
    var skylinkApiSecret: NSString!
    
    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var firstPeerVideoContainerView: UIView!
    @IBOutlet weak var secondPeerVideoContainerView: UIView!
    @IBOutlet weak var thirdPeerVideoContainerView: UIView!
    @IBOutlet weak var firstPeerLabel: UILabel!
    @IBOutlet weak var secondPeerLabel: UILabel!
    @IBOutlet weak var thirdPeerLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var btnAudioTap: UIButton!
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnCameraTap: UIButton!
    @IBOutlet weak var videoAspectSegmentControl: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let ROOM_NAME = "MULTI-VIDEO-CALL-ROOM"
    var isRoomLocked: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("imat_viewDidLoad")
        NSLog("SKYLINKConnection version = %@", SKYLINKConnection.getSkylinkVersion())
        self.title = "Multi Party Video Call"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel.png"), style: .Plain, target: self, action: #selector(MultiVideoCallViewController.disConnect))
        let infoButton: UIButton = UIButton(type: .InfoLight)
        infoButton.addTarget(self, action: #selector(MultiVideoCallViewController.showInfo), forControlEvents: .TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        self.peersInfos = [:]
        self.isRoomLocked = false
        
        // Creating configuration
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
        
        self.skylinkConnection.connectToRoomWithSecret(self.skylinkApiSecret! as String, roomName: ROOM_NAME, userInfo: nil)
        
        //Disable Button
        btnFlipCamera.enabled = false
        btnAudioTap.enabled = false
        btnCameraTap.enabled = false
        lockButton.enabled = false
        
    }
    
    func disConnect() {
        NSLog("imat_disConnect")
        self.activityIndicator.startAnimating()
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
    
    func AlertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true) {
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.updatePeersVideosFrames()
    }
    
    // SKYLINK SDK Delegates methods
    
    // MARK: SKYLINKConnectionMediaDelegate
    
    func connection(connection: SKYLINKConnection, didChangeVideoSize videoSize: CGSize, videoView: UIView) {
        
        if videoSize.height > 0 && videoSize.width > 0 {
            let correspondingContainerView: UIView = self.containerViewForVideoView(videoView)
            if !correspondingContainerView.isEqual(self.localVideoContainerView) {
                let i: Int = self.indexForContainerView(correspondingContainerView)
                
                
                let videoView : AnyObject = (self.peersInfos[peerIds[i]]?["videoView"])!
                let videoSize = NSValue(CGSize: videoSize)
                let isAudioMuted : AnyObject = (self.peersInfos[peerIds[i]]?["isAudioMuted"])!
                let isVideoMuted : AnyObject = (self.peersInfos[peerIds[i]]?["isVideoMuted"])!
                
                if i != NSNotFound {
                    self.peersInfos[peerIds[i]] = [
                        "videoView" : videoView,
                        "videoSize" : videoSize,
                        "isAudioMuted" : isAudioMuted,
                        "isVideoMuted" : isVideoMuted]
                }
            }
            
            videoView.frame =
                (self.videoAspectSegmentControl.selectedSegmentIndex == 0 || correspondingContainerView.isEqual(self.localVideoContainerView)) ? self.aspectFillRectForSize(videoSize, containedInRect: correspondingContainerView.frame): AVMakeRectWithAspectRatioInsideRect(videoSize, correspondingContainerView.bounds)
        }
        self.updatePeersVideosFrames()
        
    }
    
    func connection(connection: SKYLINKConnection, didToggleAudio isMuted: Bool, peerId: String) {
        
        let bool = self.peersInfos.allKeys.contains({(peerId) -> Bool in
            return true
        })
        if (bool) {
            let videoView : AnyObject = (self.peersInfos[peerId]?["videoView"])!
            let videoSize : AnyObject = (self.peersInfos[peerId]?["videoSize"])!
            let isAudioMuted = Int(isMuted)
            let isVideoMuted : AnyObject = (self.peersInfos[peerId]?["isVideoMuted"])!
            self.peersInfos[peerId] = [
                "videoView" : videoView,
                "videoSize" : videoSize,
                "isAudioMuted" : isAudioMuted,
                "isVideoMuted" : isVideoMuted]
        }
        self.refreshPeerViews()
        
    }
    
    func connection(connection: SKYLINKConnection, didToggleVideo isMuted: Bool, peerId: String) {
        NSLog("imat_didToggleVideo")
        let bool = self.peersInfos.allKeys.contains({(peerId) -> Bool in
            return true
        })
        
        if (bool) {
            let videoView : AnyObject = (self.peersInfos[peerId]?["videoView"])!
            let videoSize : AnyObject = (self.peersInfos[peerId]?["videoSize"])!
            let isAudioMuted : AnyObject = (self.peersInfos[peerId]?["isAudioMuted"])!
            let isVideoMuted = Int(isMuted)
            self.peersInfos[peerId] = [
                "videoView" : videoView,
                "videoSize" : videoSize,
                "isAudioMuted" : isAudioMuted,
                "isVideoMuted" : isVideoMuted]
        }
        self.refreshPeerViews()
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
    
    func connection(connection: SKYLINKConnection, didConnectWithMessage errorMessage: String, success isSuccess: Bool) {
        
        if isSuccess {
            NSLog("Inside %@", #function)
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.localVideoContainerView.alpha = 1
            })
        }
        else {
            let msgTitle: String = "Connection failed"
            let msg: String = errorMessage
            AlertMessage(msgTitle, msg:msg)
            self.navigationController!.popViewControllerAnimated(true)
        }
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            self.activityIndicator.stopAnimating()
            //Enabled Btn
            self.btnFlipCamera.enabled = true
            self.btnAudioTap.enabled = true
            self.btnCameraTap.enabled = true
            self.lockButton.enabled = true
        })
    }
    
    func connection(connection: SKYLINKConnection, didLockTheRoom lockStatus: Bool, peerId: String) {
        isRoomLocked = lockStatus
        
        self.lockButton.setImage(UIImage(named: ((self.isRoomLocked.boolValue) ? "LockFilled" : "Unlock.png")), forState: .Normal)
    }
    
    
    func connection(connection: SKYLINKConnection, didRenderUserVideo userVideoView: UIView) {
        
        self.addRenderedVideo(userVideoView, insideContainer: self.localVideoContainerView, mirror: true)
    }
    
    func connection(connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String) {
        
        let msgTitle: String = "Disconnected"
        let alertController = UIAlertController(title: msgTitle , message: errorMessage, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: {
            self.disConnect()
        })
    }
    
    // MARK: SKYLINKConnectionRemotePeerDelegate
    func connection(connection: SKYLINKConnection, didJoinPeer userInfo: AnyObject, mediaProperties pmProperties: SKYLINKPeerMediaProperties, peerId: String) {
        
        if !(self.peerIds.contains(peerId)) {
            self.peerIds.append(peerId)
        }
        if self.peerIds.count >= 4 {
            self.lockRoom(true)
        }
        
        var bool = false
        for i in self.peersInfos.allKeys {
            if i.isEqualToString(peerId) {
                bool = true
            }
        }
        
        if !(bool) {
            self.peersInfos.addEntriesFromDictionary([peerId: ["videoView": NSNull(), "videoSize": NSNull(), "isAudioMuted": NSNull(), "isVideoMuted": NSNull()]])
        }
        
        let videoView: AnyObject = (self.peersInfos[peerId]?["videoView"])!
        let size = CGSize(width: pmProperties.videoWidth, height: pmProperties.videoHeight)
        let videoSize = NSValue(CGSize: size)
        let isAudioMuted = NSNumber(bool: pmProperties.isAudioMuted)
        let isVideoMuted = NSNumber(bool: pmProperties.isVideoMuted)
        self.peersInfos[peerId] = [
            "videoView" : videoView,
            "videoSize" : videoSize,
            "isAudioMuted" : isAudioMuted,
            "isVideoMuted" : isVideoMuted]
        self.refreshPeerViews()
        
    }
    
    func connection(connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String, peerId: String) {
        
        NSLog("Peer with id %@ left the room with message: %@", peerId, errorMessage);
        if(self.peerIds.count != 0) {
            self.peerIds.removeAtIndex(peerIds.indexOf(peerId)!)
            self.peersInfos.removeObjectForKey(peerId)
        }
        self.lockRoom(false)
        self.refreshPeerViews()
        
    }
    
    func connection(connection: SKYLINKConnection, didRenderPeerVideo peerVideoView: UIView, peerId: String) {
        
        if !self.peerIds.contains(peerId) {
            self.peerIds.append(peerId)
        }
        var bool = false
        for i in self.peersInfos.allKeys {
            if i.isEqualToString(peerId) {
                bool = true
            }
        }
        
        if !(bool) {
            self.peersInfos.addEntriesFromDictionary([peerId: ["videoView": NSNull(), "videoSize": NSNull(), "isAudioMuted": NSNull(), "isVideoMuted": NSNull()]])
        }
        
        let videoSize: AnyObject = (self.peersInfos[peerId]?["videoSize"])!
        let isAudioMuted: AnyObject = (self.peersInfos[peerId]?["isAudioMuted"])!
        let isVideoMuted: AnyObject = (self.peersInfos[peerId]?["isVideoMuted"])!
        
        self.peersInfos[peerId] = [
            "videoView" : peerVideoView,
            "videoSize" : videoSize,
            "isAudioMuted" : isAudioMuted,
            "isVideoMuted" : isVideoMuted]
        self.refreshPeerViews()
    }
    
    //End of Skylink SDK functions
    
    // MARK: Utils
    
    func updatePeersVideosFrames() {
        var pvView: AnyObject?
        var pvSize: AnyObject?
        
        for (var i = 0; i < self.peerIds.count && i < 3; i += 1) {
            pvView = (self.peersInfos[self.peerIds[i]]?["videoView"])!
            pvSize = (self.peersInfos[self.peerIds[i]]?["videoSize"])!
            
            if (pvView is UIView && pvSize is NSValue) {
                ((pvView as! UIView)).frame = (self.videoAspectSegmentControl.selectedSegmentIndex == 0) ? self.aspectFillRectForSize((pvSize as! NSValue).CGSizeValue(), containedInRect:(self.containerViewForVideoView(pvView as! UIView).frame)): AVMakeRectWithAspectRatioInsideRect(((pvSize as! NSValue)).CGSizeValue(), self.containerViewForVideoView(pvView as! UIView).bounds)
            }
        }
    }
    
    func lockRoom(shouldLock: Bool) {
        (shouldLock) ? self.skylinkConnection.lockTheRoom() : self.skylinkConnection.unlockTheRoom()
        isRoomLocked = shouldLock
        self.lockButton.setImage(UIImage(named: ((self.isRoomLocked.boolValue) ? "LockFilled" : "Unlock.png")), forState: .Normal)
    }
    
    func containerViewForVideoView(videoView: UIView) -> UIView {
        
        var correspondingContainerView: UIView!
        
        if videoView.isDescendantOfView(self.localVideoContainerView) {
            correspondingContainerView = self.localVideoContainerView
        }
        else if videoView.isDescendantOfView(self.firstPeerVideoContainerView) {
            correspondingContainerView = self.firstPeerVideoContainerView
        }
        else if videoView.isDescendantOfView(self.secondPeerVideoContainerView) {
            correspondingContainerView = self.secondPeerVideoContainerView
        }
        else if videoView.isDescendantOfView(self.thirdPeerVideoContainerView) {
            correspondingContainerView = self.thirdPeerVideoContainerView
        }
        return correspondingContainerView
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
    
    func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView, mirror shouldMirror: Bool) {
        NSLog("I_addRenderedVideo")
        videoView.frame = containerView.bounds
        if shouldMirror {
            videoView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
        }
        
        for subview: UIView in containerView.subviews {
            subview.removeFromSuperview()
        }
        
        containerView.insertSubview(videoView, atIndex: 0)
    }
    
    func indexForContainerView(v: UIView) -> Int {
        return [self.firstPeerVideoContainerView, self.secondPeerVideoContainerView, self.thirdPeerVideoContainerView].indexOfObject(v)
    }
    
    func refreshPeerViews() {
        
        let peerContainerViews = [self.firstPeerVideoContainerView, self.secondPeerVideoContainerView, self.thirdPeerVideoContainerView]
        var peerLabels = [self.firstPeerLabel, self.secondPeerLabel, self.thirdPeerLabel]
        
        
        for viewToClean: UIView in peerContainerViews {
            for aSubview: UIView in viewToClean.subviews {
                aSubview.removeFromSuperview()
            }
        }
        
        for i in 0 ..< peersInfos.count  {
            let index: Int = self.peerIds.indexOf(peerIds[i])!
            
            let videoView: AnyObject = (self.peersInfos[peerIds[i]]?["videoView"])!
            if (index < peerContainerViews.count) {
                if videoView is NSNull {
                    self.AlertMessage("Warning",msg: "Cannot render the video view. Camera not found")
                }
                else {
                    self.addRenderedVideo(videoView as! UIView, insideContainer: peerContainerViews[index], mirror: false)
                }
            }
            // refresh the label
            let audioMuted: AnyObject = (self.peersInfos[peerIds[i]]?["isAudioMuted"])!
            
            let videoMuted: AnyObject = (self.peersInfos[peerIds[i]]?["isVideoMuted"])!
            
            var mutedInfos: String = ""
            if (audioMuted is NSNumber) && CBool(audioMuted as! NSNumber) {
                mutedInfos = "Audio muted"
            }
            if (videoMuted is NSNumber) && CBool(videoMuted as! NSNumber) {
                mutedInfos = mutedInfos.characters.count != 0 ? "Video & ".stringByAppendingString(mutedInfos) : "Video muted"
            }
            if (index < peerLabels.count) {
                peerLabels[index].text = mutedInfos
            }
            if (index < peerLabels.count) {
                peerLabels[index].hidden = !(mutedInfos.characters.count != 0)
            }
        }
        
        for i in self.peerIds.count ..< peerLabels.count {
            ((peerLabels[i] as UILabel)).hidden = true
        }
        self.updatePeersVideosFrames()
    }
    
    // MARK: IB Action Function
    @IBAction func toogleVideoTap(sender: AnyObject) {
        self.skylinkConnection.muteVideo(!self.skylinkConnection.isVideoMuted())
        sender.setImage(UIImage(named: ((self.skylinkConnection.isVideoMuted()) ? "NoVideoFilled.png" : "VideoCall.png")), forState: .Normal)
        self.localVideoContainerView.hidden = (self.skylinkConnection.isVideoMuted)()
    }
    
    @IBAction func toogleSoundTap(sender: AnyObject) {
        self.skylinkConnection.muteAudio(!self.skylinkConnection.isAudioMuted())
        sender.setImage(UIImage(named: ((self.skylinkConnection.isAudioMuted()) ? "NoMicrophoneFilled.png" : "Microphone.png")), forState: .Normal)
    }
    
    @IBAction func switchCameraTap(sender: AnyObject) {
        self.skylinkConnection.switchCamera()
    }
    
    @IBAction func switchLockTap(sender: AnyObject) {
        self.lockRoom(!isRoomLocked)
    }
    
    @IBAction func videoAspectSegmentControlChanged(sender: AnyObject) {
        self.updatePeersVideosFrames()
    }
    
    
}
