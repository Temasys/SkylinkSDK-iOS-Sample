//
//  RoomViewController.swift
//  SampleAppSwift
//
//  Created by macbookpro on 26/02/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//


import Foundation
import MediaPlayer
import UIKit

extension SKYLINKConnection {
    func getDisplayName(peerId: String) -> String {
        let trimmedPeerId: String = peerId.substringWithRange(Range(start: peerId.startIndex,
            end: advance(peerId.startIndex, 6)))
        var displayName: String = self.getUserInfo(peerId) as? String ?? trimmedPeerId
        displayName = count(displayName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())) == 0 ? trimmedPeerId : displayName
        return displayName
    }
}

class ControlButton: UIButton {
    var myState: Int = 1
}

@objc class RoomViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionRemotePeerDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionFileTransferDelegate, TEMVideoViewDelegate {

    let PARENT_PADDING: CGFloat = 20
    let SIBLING_PADDING: CGFloat = 8
    
    var timer: NSTimer?
    var toastTimer: NSTimer?
    var controlViewTimer: NSTimer?
    
    private var timerCount: Int = 0
    
    @IBOutlet weak var lblCallType: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblToast: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    @IBOutlet var controlView: UIView!
    @IBOutlet weak var btnVideo: ControlButton!
    @IBOutlet weak var btnAudio: ControlButton!
    @IBOutlet weak var btnLock: ControlButton!
    
    private weak var volumeView: MPVolumeView?
    
    private var displayName: String?
    private var roomName: String?
    
    private var myConnection: SKYLINKConnection?
    
    private var statusBarOrientation: UIInterfaceOrientation?
    
    private var remotePeerArray: Array<String> = Array<String>()
    private var remoteVideoViewArray: Array<TEMRichVideoView> = Array<TEMRichVideoView>()
    
    private weak var localVideoView: TEMRichVideoView?
    private weak var remoteVideoView: TEMRichVideoView?
    
    private var presenceNavigationController: TEMPresenceNavigationController?
    private weak var presenceTableViewController: TEMPresenceTableViewController?
    
    /*override init () {
        super.init()
    }*/
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(displayName: String, roomName: String) {
        super.init(nibName: "RoomViewController", bundle: nil)
        self.displayName = displayName
        self.roomName = roomName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UIApplication.sharedApplication().idleTimerDisabled = true
        statusBarOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        lblTime.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        lblToast.layer.cornerRadius = lblToast.bounds.size.height/4.0
        lblToast.layer.masksToBounds = true
        
        constructPresenceView()
        
        // Create configuration
        let config: SKYLINKConnectionConfig = SKYLINKConnectionConfig()
        config.video = true
        config.audio = true
        config.fileTransfer = true
        config.dataChannel = true
        config.timeout = 30
        (UIApplication.sharedApplication().delegate as! AppDelegate).appConfig = config
        
        // Instante SKYLINKConnection
        SKYLINKConnection.setVerbose(true)
        myConnection = SKYLINKConnection(config: config, appKey: <#app key#>)
        myConnection?.lifeCycleDelegate = self
        myConnection?.remotePeerDelegate = self
        myConnection?.mediaDelegate = self
        myConnection?.messagesDelegate = self
        myConnection?.fileTransferDelegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presenceTitleBarViewTapped:", name: "MINIMIZE_PRESENCE", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let returnValue: Bool! = myConnection?.connectToRoomWithSecret(<#secret#>, roomName: roomName, userInfo: displayName)
        if returnValue != nil && !returnValue {
            println(__FUNCTION__ + "You are already connected")
        }
    }
    
    private var downTime: Bool = false
    override func viewDidLayoutSubviews() {
        if downTime == false {
            repositionControlAndVolume()
        }
        if statusBarOrientation != UIApplication.sharedApplication().statusBarOrientation {
            statusBarOrientation = UIApplication.sharedApplication().statusBarOrientation
            // myConnection?.reportRotation()
            
            presenceNavigationController?.view.frame = getRespectivePresenceFrame()
            let presenceMinimize: Bool! = presenceNavigationController?.minimize
            if presenceMinimize != nil && presenceMinimize == true {
                presenceNavigationController?.refurbish(true);
            }
            repositionControlAndVolume()
            
            // Accomodate local video view
            if remoteVideoViewArray.count == 0 {
                localVideoView?.frame = self.view.bounds
            } else {
                let selfViewBoundsSize: CGSize = self.view.bounds.size
                let localVideoViewBoundsSize: CGSize! = localVideoView?.bounds.size
                localVideoView?.frame = CGRectMake(selfViewBoundsSize.width-(PARENT_PADDING+localVideoViewBoundsSize.height), CGRectGetMaxY(btnClose.frame)+SIBLING_PADDING, localVideoViewBoundsSize.height, localVideoViewBoundsSize.width)
            }
            
            remoteVideoView?.frame = self.view.bounds
            
            rearrangeVideoFrames()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    // MARK: - public methods
    
    func sendChatMessage(message: String, target: String!) {
        let haveDataChannel: Bool! = (UIApplication.sharedApplication().delegate as! AppDelegate).appConfig?.dataChannel
        if target != nil && haveDataChannel == true {
            myConnection?.sendDCMessage(message, peerId: target)
        } else {
            myConnection?.sendCustomMessage(message, peerId: target)
        }
    }
    
    func startFileTransfer(userId: String!, fileURL: NSURL, transferType: SKYLINKAssetType) {
        if userId != nil {
            TEMObjCBridge.sharedInstance().try({ () -> Void in
                self.sendFileTransferRequest(fileURL, assetType: transferType)
            }, catch: { (exception: NSException!) -> Void in
                self.showSimpleAlert(nil, message: "Another file transfer is in progress with this user. Please try again after the other file transfer is ended. Thanks!", buttonTitle: "I've got it!")
            }, finally: nil)
        } else {
            myConnection?.sendFileTransferRequest(fileURL, assetType: transferType)
        }
    }
    
    // MARK: - NSNotification
    
    func keyboardWillShow (notification: NSNotification) {
        var keyboardFrame: CGRect?
        var animationDuration: Double?
        
        if let userInfo = notification.userInfo {
            if let frameObject: AnyObject = userInfo[UIKeyboardFrameEndUserInfoKey] {
                let frameValue: NSValue = frameObject as! NSValue
                keyboardFrame = frameValue.CGRectValue()
                keyboardFrame = self.view.convertRect(keyboardFrame!, toView: self.view)
            }
            if let durationObject: AnyObject = userInfo[UIKeyboardAnimationDurationUserInfoKey] {
                animationDuration = durationObject as? Double
            }
        }
        
        if keyboardFrame != nil {
            var keyboardSize: CGSize! = keyboardFrame?.size
            var keyboardHeight: CGFloat = keyboardSize.height;
            var adjustedFrame: CGRect = getRespectivePresenceFrame()
            adjustedFrame = CGRectMake(adjustedFrame.origin.x, adjustedFrame.origin.y-keyboardHeight, adjustedFrame.size.width, adjustedFrame.size.height);
            UIView.beginAnimations("MoveChatUp", context: nil)
            UIView.setAnimationDuration(animationDuration!)
            self.presenceNavigationController?.view.frame = adjustedFrame;
            UIView.commitAnimations()
        }
    }
    
    func keyboardWillHide (notification: NSNotification) {
        var animationDuration: Double?
        if let userInfo = notification.userInfo {
            if let durationObject: AnyObject = userInfo[UIKeyboardAnimationDurationUserInfoKey] {
                animationDuration = durationObject as? Double
            }
        }
        
        UIView.beginAnimations("MoveChatDown", context: nil)
        UIView.setAnimationDuration(animationDuration!)
        self.presenceNavigationController?.view.frame = self.getRespectivePresenceFrame()
        UIView.commitAnimations()
    }
    
    func presenceTitleBarViewTapped (notification: NSNotification) {
        var initialValue: Bool! = presenceNavigationController?.minimize
        var finalValue: Bool! = !initialValue
        UIView.beginAnimations("MinimizeChat", context: nil)
        UIView.setAnimationDuration(0.3)
        self.presenceNavigationController?.minimize = finalValue
        UIView.commitAnimations()
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    
    func connection(connection: SKYLINKConnection!, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        if isSuccess {
            println("Inside " + __FUNCTION__)
            #if arch(i386) || arch(x86_64)
                let videoView: TEMRichVideoView = TEMRichVideoView(frame: self.view.bounds, videoView: UIView())
                videoView.isRemote = false
                videoView.delegate = self
                self.view.insertSubview(videoView, belowSubview: lblTime)
                localVideoView = videoView
            #endif
            
            let config: SKYLINKConnectionConfig! = (UIApplication.sharedApplication().delegate as! AppDelegate).appConfig
            let haveVideo: Bool = config.video && config.audio
            let haveFileTransfer: Bool = config.fileTransfer && config.dataChannel

            if !haveVideo {
                var configText: String
                if !config.audio && !haveFileTransfer {
                    configText = "Chat Only"
                } else if !config.audio && haveFileTransfer {
                    configText = "Data Only"
                } else {
                    configText = "Audio Call"
                    btnVideo.enabled = false
                }
                lblCallType.text = configText
                lblCallType.hidden = false
            }
            
            let pad: Bool = (UIApplication.sharedApplication().delegate as! AppDelegate).isPad
            if config.audio && !pad {
                let myVolumeView: MPVolumeView = MPVolumeView(frame: controlView.frame)
                myVolumeView.showsVolumeSlider = false
                myVolumeView.alpha = 0.0
                self.view.addSubview(myVolumeView)
                self.volumeView = myVolumeView
            }
        } else {
            showSimpleAlert("Connection Refused!", message: errorMessage, buttonTitle: "I've got it!")
        }
    }
    
    func connection(connection: SKYLINKConnection!, didRenderUserVideo userVideoView: UIView!) {
        let videoView: TEMRichVideoView = TEMRichVideoView(frame: self.view.bounds, videoView: userVideoView)
        videoView.setRemote(false)
        videoView.delegate = self
        self.view.insertSubview(videoView, belowSubview: lblTime)
        localVideoView = videoView
    }

    func connection(connection: SKYLINKConnection!, didLockTheRoom lockStatus: Bool, peerId: String!) {
        let lockMessage: String = lockStatus ? "locked" : "unlocked"
        showToast("'" + connection.getDisplayName(peerId) + "' has " + lockMessage + " the room!")
        if (lockStatus) {
            btnLock.setImage(UIImage(named: "unlock"), forState: UIControlState.Normal)
            btnLock.myState = 1;
        } else {
            btnLock.setImage(UIImage(named: "lock"), forState: UIControlState.Normal)
            btnLock.myState = 0;
        }
    }
    
    func connection(connection: SKYLINKConnection!, didReceiveWarning message: String!) {
        println(__FUNCTION__)
    }

    func connection(connection: SKYLINKConnection!, didDisconnectWithMessage errorMessage: String!) {
        let controller: UIAlertController = UIAlertController(title: "Connection Disconnected!", message: errorMessage, preferredStyle: .Alert)
        let action: UIAlertAction = UIAlertAction(title: "I've got it!", style: .Default) { action -> Void in
            self.cleanUp()
            self.downTime = true
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.myConnection?.disconnect()
                self.myConnection = nil
            })
        }
        controller.addAction(action)
        self.presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - SKYLINKConnectionRemotePeerDelegate
    
    func connection(connection: SKYLINKConnection!, didJoinPeer userInfo: AnyObject!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        let displayName: String = retrieveDisplayName(userInfo, peerId: peerId)
        showToast("'" + displayName + "' is now in the room!")
        if remotePeerArray.count == 0 {
            presenceNavigationController?.view.hidden = false
            startTimer()
        }
        remotePeerArray.append(peerId)
        presenceTableViewController?.addParticipant(displayName, peerId: peerId)
    }
    
    func connection(connection: SKYLINKConnection!, didRenderPeerVideo peerVideoView: UIView!, peerId: String!) {
        let localVideoFrame: CGRect! = localVideoView?.frame
        let videoView: TEMRichVideoView = TEMRichVideoView(frame: localVideoFrame, videoView: peerVideoView)
        videoView.setRemote(true)
        videoView.delegate = self
        videoView.ID = peerId
        let dispName: String! = myConnection?.getDisplayName(peerId)
        videoView.setTitle(dispName)
        
        if remoteVideoViewArray.count == 0 {
            let localVideoViewSize: CGSize! = localVideoView?.bounds.size
            let localVideoViewWidth: CGFloat = localVideoViewSize.width/4
            let localVideoViewHeight: CGFloat = localVideoViewSize.height/4
            
            let selfViewSize: CGSize! = self.view.bounds.size
            UIView.beginAnimations("SelfViewReframed", context: nil)
            UIView.setAnimationDuration(0.3)
            localVideoView?.frame = CGRectMake(selfViewSize.width-(PARENT_PADDING+localVideoViewWidth), CGRectGetMaxY(btnClose.frame)+SIBLING_PADDING, localVideoViewWidth, localVideoViewHeight)
            UIView.commitAnimations()
            remoteVideoView = videoView
        } else if remoteVideoViewArray.count == 1 {
            let videoViewSize: CGSize = videoView.bounds.size
            videoView.frame = CGRectMake(videoView.frame.origin.x, CGRectGetMaxY(self.view.frame)-(PARENT_PADDING+videoViewSize.height), videoViewSize.width, videoViewSize.height)
        } else {
            let selfViewBoundsSize: CGSize = self.view.bounds.size
            let videoViewBoundsSize: CGSize = videoView.bounds.size
            let totalThumbnails: Int = remoteVideoViewArray.count
            let videoViewFrameX: CGFloat = selfViewBoundsSize.width - (PARENT_PADDING + CGFloat(totalThumbnails-1)*SIBLING_PADDING + CGFloat(totalThumbnails)*videoViewBoundsSize.width)
            videoView.frame = CGRectMake(videoViewFrameX, CGRectGetMaxY(self.view.frame)-(PARENT_PADDING+videoView.frame.size.height), videoViewBoundsSize.width, videoViewBoundsSize.height)
        }
        
        remoteVideoViewArray.append(videoView)
        self.view.insertSubview(videoView, belowSubview: localVideoView!)
    }
    
    func connection(connection: SKYLINKConnection!, didReceiveUserInfo userInfo: AnyObject!, peerId: String!) {
        let nick: String = retrieveDisplayName(userInfo, peerId: peerId)
        var oldNick: String! = presenceTableViewController?.updateParticipant(nick, peerId: peerId)
        showToast("'" + oldNick + "' is now known as '" + nick + "'")
    }
    
    func connection(connection: SKYLINKConnection!, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        let displayName: String = connection.getDisplayName(peerId)
        showToast("'" + displayName + "' has left the room!")
        
        for var i = 0; i < remotePeerArray.count; i++ {
            let remotePeerId: String = remotePeerArray[i]
            if peerId == remotePeerId {
                remotePeerArray.removeAtIndex(i)
                presenceTableViewController?.deleteParticipant(peerId)
                if remotePeerArray.count == 0 {
                    presenceNavigationController?.view.hidden = true
                    presenceNavigationController?.minimize = true
                    myConnection?.muteAudio(false)
                    btnAudio.setImage(UIImage(named: "disable_audio"), forState: UIControlState.Normal)
                    btnAudio.myState = 0
                    myConnection?.muteVideo(false)
                    btnVideo.setImage(UIImage(named: "disable_camera"), forState: UIControlState.Normal)
                    btnVideo.myState = 0
                    stopTimer()
                }
                break
            }
        }
        
        for var i = 0; i < remoteVideoViewArray.count; i++ {
            let videoView: TEMRichVideoView = remoteVideoViewArray[i]
            if videoView.ID == peerId {
                deleteRemoteVideoView(videoView, dex: i)
                break
            }
        }
    }

    // MARK: - SKYLINKConnectionMediaDelegate
    
    func connection(connection: SKYLINKConnection!, didChangeVideoSize videoSize: CGSize, videoView: UIView!) {
        if videoView === localVideoView?.getRenderSurface() {
            localVideoView?.layoutSubviews(videoSize)
            return
        }
        
        for vidView in remoteVideoViewArray {
            if vidView.getRenderSurface() === videoView {
                vidView.layoutSubviews(videoSize)
                break
            }
        }
    }
    
    func connection(connection: SKYLINKConnection!, didToggleAudio isMuted: Bool, peerId: String!) {
        let displayName: String = connection.getDisplayName(peerId)
        let muteString = isMuted ? "muted" : "unmuted"
        let message: String = displayName + "'s audio is " + muteString + " now"
        showToast(message)
    }
    
    func connection(connection: SKYLINKConnection!, didToggleVideo isMuted: Bool, peerId: String!) {
        for videoView in remoteVideoViewArray {
            if videoView.ID == peerId {
                videoView.setEnabled(!isMuted)
                break
            }
        }
        
        let displayName: String = connection.getDisplayName(peerId)
        let muteString = isMuted ? "muted" : "unmuted"
        let message: String = displayName + "'s video is " + muteString + " now"
        showToast(message)
    }

    // MARK: - SKYLINKConnectionMessagesDelegate
    
    func connection(connection: SKYLINKConnection!, didReceiveCustomMessage message: AnyObject!, `public` isPublic: Bool, peerId: String!) {
        var castedMessage: String! = message as? String
        presenceTableViewController?.addChatMessage(castedMessage, nick: connection.getDisplayName(peerId), peerId: peerId, isPublic: isPublic)
        var minimized: Bool! = presenceNavigationController?.minimize
        if minimized == true {
            presenceTableViewController?.highlightPanelButton()
        }
    }
    
    func connection(connection: SKYLINKConnection!, didReceiveDCMessage message: AnyObject!, `public` isPublic: Bool, peerId: String!) {
        var castedMessage: String! = message as? String
        presenceTableViewController?.addChatMessage(castedMessage, nick: connection.getDisplayName(peerId), peerId: peerId, isPublic: isPublic)
        var minimized: Bool! = presenceNavigationController?.minimize
        if minimized == true {
            presenceTableViewController?.highlightPanelButton()
        }
    }

    func connection(connection: SKYLINKConnection!, didReceiveBinaryData data: NSData!, peerId: String!) {
        // let dataLength: int = data.length
        // println(__FUNCTION__ + "::Received binary data of length " + dataLength + " from " + peerId)
    }
    
    // MARK: - SKYLINKConnectionFileTransferDelegate
    
    func connection(connection: SKYLINKConnection!, didReceiveRequest filename: String!, peerId: String!) {
        let displayName: String = connection.getDisplayName(peerId)
        let message: String = String("The user '" + displayName + "' wants to send you a file with name '" + filename + "'. Do you want to accept it?")
        let controller: UIAlertController = UIAlertController(title: "Permission!", message: message, preferredStyle: .Alert)
        let actionYes: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
            self.addProgressView(peerId)
            connection.acceptFileTransfer(true, filename: filename, peerId: peerId)
        }
        controller.addAction(actionYes)
        let actionNo: UIAlertAction = UIAlertAction(title: "No", style: .Default) { action -> Void in
            connection.acceptFileTransfer(false, filename: filename, peerId: peerId)
        }
        controller.addAction(actionNo)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func connection(connection: SKYLINKConnection!, didReceivePermission isPermitted: Bool, filename: String!, peerId: String!) {
        if isPermitted == true {
            addProgressView(peerId)
        } else {
            let displayName: String = connection.getDisplayName(peerId)
            let message: String = String("We are sorry that the user '" + displayName + "' has refused to accept your '" + filename + "' sending request")
            showSimpleAlert(nil, message: message, buttonTitle: "I've got it!")
        }
    }
    
    func connection(connection: SKYLINKConnection!, didDropTransfer filename: String!, reason message: String!, isExplicit: Bool, peerId: String!) {
        let displayName: String = connection.getDisplayName(peerId)
        let userMessage: String = String("'" + displayName + "' has canceled the file being transferred")
        if isExplicit == true {
            showToast(userMessage)
        } else {
            showSimpleAlert(nil, message: message, buttonTitle: "I've got it!")
        }
        removeProgressView(peerId)
    }
    
    func connection(connection: SKYLINKConnection!, didCompleteTransfer filename: String!, fileData: NSData!, peerId: String!) {
        if fileData != nil {
            let fileExtension: String! = filename.componentsSeparatedByString(".").last
            let newFileName: String = filename.stringByReplacingOccurrencesOfString(" ", withString: "_")
            let image: UIImage! = UIImage(data: fileData)
            if TEMObjCBridge.sharedInstance().isImage(fileExtension) && image != nil {
                TEMObjCBridge.sharedInstance().saveImageToPhotoAlbum(image, name: filename)
            } else {
                let pathArray: Array<AnyObject> = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                let filePath: String = (pathArray.first as! String).stringByAppendingPathComponent(filename)
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) == true && TEMObjCBridge.sharedInstance().removeFileAtPath(filePath) {
                    return
                }
                
                if fileData.writeToFile(filePath, atomically: true) == false {
                    println(__FUNCTION__ + "::Error while writing '" + filePath + "'")
                } else {
                    if TEMObjCBridge.sharedInstance().isMovie(fileExtension) == true && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) == true {
                        let videoPathURL: NSURL! = NSURL(fileURLWithPath: filePath)
                        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(videoPathURL, completionBlock: { (url: NSURL!, error: NSError!) -> Void in
                            if error != nil {
                                println(__FUNCTION__ + "::Error while saving '" + filename + "'->" + error.localizedDescription)
                            } else {
                                TEMObjCBridge.sharedInstance().removeFileAtPath(filePath)
                            }
                        })
                    }
                }
            }
        }
        removeProgressView(peerId)
    }
    
    // MARK: - TEMVideoViewDelegate
    
    func videoViewIsTapped(vidView : TEMVideoView) {
        self.view.endEditing(true)
        if vidView === remoteVideoView || vidView === localVideoView {
            if remoteVideoViewArray.count > 0 {
                showControlView()
            }
        } else {
            swapVideosAnimated(vidView as! TEMRichVideoView, animated: true)
        }
    }
    
    // MARK: - private methods
    
    private func cleanUp() {
        remotePeerArray.removeAll(keepCapacity: false)
        
        for videoView in remoteVideoViewArray {
            videoView.removeFromSuperview()
        }
        remoteVideoViewArray.removeAll(keepCapacity: false)
        
        presenceNavigationController?.view.removeFromSuperview()
        presenceNavigationController = nil
        
        stopTimer()
        localVideoView?.removeFromSuperview()
    }
    
    private func constructPresenceView() {
        // initialize presence panel
        let tableViewController: TEMPresenceTableViewController = TEMPresenceTableViewController(nibName: "TEMPresenceTableViewController", bundle: nil)
        presenceNavigationController = TEMPresenceNavigationController(rootViewController: tableViewController)
        presenceTableViewController = tableViewController
        presenceNavigationController?.view.frame = getRespectivePresenceFrame()
        let presenceNavView: UIView! = presenceNavigationController?.view
        self.view.addSubview(presenceNavView)
        presenceNavView.hidden = true
    }
    
    private func deleteRemoteVideoView(videoView: TEMRichVideoView, dex: Int) {
        if remoteVideoViewArray.count == 1 {
            videoView.removeFromSuperview()
            remoteVideoViewArray.removeAtIndex(0)
            UIView.beginAnimations("LocalViewMove", context: nil)
            UIView.setAnimationDuration(0.3)
            localVideoView?.frame = self.view.bounds
            UIView.commitAnimations()
        } else {
            if videoView === remoteVideoView {
                var lastVideoView: TEMRichVideoView! = remoteVideoViewArray.last
                if lastVideoView === remoteVideoView {
                    lastVideoView = remoteVideoViewArray[remoteVideoViewArray.count-2]
                }
                swapVideosAnimated(lastVideoView, animated: false)
                videoView.removeFromSuperview()
                remoteVideoViewArray.removeAtIndex(dex)
            } else {
                videoView.removeFromSuperview()
                remoteVideoViewArray.removeAtIndex(dex)
                rearrangeVideoFrames()
            }
        }
    }
    
    private func getRespectiveControlViewFrame() -> CGRect {
        let presenceNavMinimize: Bool! = presenceNavigationController?.minimize
        
        let selfViewBoundsSize: CGSize! = self.view.bounds.size
        let presenceNavFrame: CGRect! = presenceNavigationController?.view.frame
        let controlViewBoundsSize: CGSize! = controlView.bounds.size
        
        var x: CGFloat! = 0.0
        var y: CGFloat! = 0.0;
        
        if (UIApplication.sharedApplication().delegate as! AppDelegate).isPad {
            x = CGRectGetMaxX(presenceNavFrame) + ((selfViewBoundsSize.width - presenceNavFrame.size.width) - controlViewBoundsSize.width)/2
            if presenceNavMinimize != nil && presenceNavMinimize == true {
                y = presenceNavFrame.origin.y
            } else {
                y = presenceNavigationController?.getMinimizedY()
            }
        } else {
            if (UIInterfaceOrientationIsPortrait(statusBarOrientation!)) {
                x = (selfViewBoundsSize.width - controlViewBoundsSize.width) / 2;
                if presenceNavMinimize != nil && presenceNavMinimize == true {
                    y = presenceNavFrame.origin.y
                    y = y - (SIBLING_PADDING+controlViewBoundsSize.height)
                } else {
                    y = presenceNavigationController?.getMinimizedY()
                    y = y - (SIBLING_PADDING+controlViewBoundsSize.height)
                }
            } else {
                x = CGRectGetMaxX(presenceNavFrame) + ((selfViewBoundsSize.width - presenceNavFrame.size.width) - controlViewBoundsSize.width)/2
                if presenceNavMinimize != nil && presenceNavMinimize == true {
                    y = presenceNavFrame.origin.y
                } else {
                    y = presenceNavigationController?.getMinimizedY()
                }
            }
        }
        return CGRectMake(x, y, controlViewBoundsSize.width, controlViewBoundsSize.height);
    }
    
    private func getRespectivePresenceFrame() -> CGRect {
        var screenBounds: CGRect = UIScreen.mainScreen().fixedCoordinateSpace.bounds
        var presenceNavigationFrame: CGRect = CGRectZero
        if ((UIApplication.sharedApplication().delegate as! AppDelegate).isPad) {
            var size: CGSize = CGSizeMake(screenBounds.size.width/3, screenBounds.size.width/2)
            var selfViewBoundsSize: CGSize = self.view.bounds.size
            presenceNavigationFrame = CGRectMake(0, selfViewBoundsSize.height-size.height, size.width, size.height)
        } else {
            var selfViewBoundsSize: CGSize = self.view.bounds.size
            presenceNavigationFrame = UIInterfaceOrientationIsPortrait(statusBarOrientation!) ? CGRectMake(0, 0, selfViewBoundsSize.width, selfViewBoundsSize.height) : CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.width)
        }
        return presenceNavigationFrame
    }
    
    private func rearrangeVideoFrames() {
        // Here you rearrange the remote video view frames
        var tempViewArray: Array<UIView> = Array<UIView>()
        for vidView in remoteVideoViewArray {
            if vidView !== remoteVideoView {
                tempViewArray.append(vidView)
            }
        }
        
        var w: CGFloat! = localVideoView?.bounds.size.width
        var h: CGFloat! = localVideoView?.bounds.size.height
        var x: CGFloat = self.view.bounds.size.width - PARENT_PADDING
        var y: CGFloat! = CGRectGetMaxY(self.view.bounds) - (SIBLING_PADDING+h)
        for var i = 0; i < tempViewArray.count; i++ {
            let videoView: UIView = tempViewArray[i]
            x -= w
            videoView.frame = CGRectMake(x, y, w, h)
            x -= SIBLING_PADDING
        }
    }
    
    private func repositionControlAndVolume() {
        // Reposition Control View
        let controlViewBoundsSize: CGSize = controlView.bounds.size
        controlView.frame = getRespectiveControlViewFrame()
        
        // Reposition Volume View
        if volumeView != nil {
            let volumeViewFrame: CGRect! = volumeView?.frame
            let controlViewFrame: CGRect! = controlView.frame
            volumeView?.frame = CGRectMake(controlViewFrame.origin.x, CGRectGetMinY(controlView.frame)-(SIBLING_PADDING+controlViewBoundsSize.height), controlViewBoundsSize.width, controlViewBoundsSize.height)
        }
    }
    
    private func sendFileTransferRequest(fileURL: NSURL, assetType: SKYLINKAssetType) {
        myConnection?.sendFileTransferRequest(fileURL, assetType: assetType)
    }
    
    private func retrieveDisplayName(userInfo: AnyObject, peerId: String) -> String {
        let trimmedPeerId: String = peerId.substringWithRange(Range(start: peerId.startIndex,
            end: advance(peerId.startIndex, 6)))
        var displayName: String = userInfo as? String ?? trimmedPeerId
        displayName = count(displayName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())) == 0 ? trimmedPeerId : displayName
        return displayName
    }
    
    private func showSimpleAlert(title: String!, message: String, buttonTitle: String) {
        let controller: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        controller.addAction(UIAlertAction(title: buttonTitle, style: .Default, handler: nil))
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    private func swapVideosAnimated(videoView: TEMRichVideoView, animated: Bool) {
        let bigFrame: CGRect! = remoteVideoView?.frame
        let smallFrame: CGRect = videoView.frame
        let duration: Double = animated ? 0.3 : 00
        
        videoView.lblTitle!.hidden = true
        remoteVideoView?.lblTitle!.hidden = true
        remoteVideoView?.alpha = 0

        if animated {
            UIView.animateWithDuration(duration, animations: { () -> Void in
                videoView.frame = bigFrame
                self.remoteVideoView?.frame = smallFrame
                self.remoteVideoView?.alpha = 1
            }) { completed -> Void in
                self.view.sendSubviewToBack(videoView)
                let tmpVideoView: TEMRichVideoView! = self.remoteVideoView
                self.remoteVideoView = videoView
                self.remoteVideoView?.lblTitle!.hidden = false
                tmpVideoView.lblTitle!.hidden = false
            }
        } else {
            videoView.frame = bigFrame
            self.remoteVideoView?.frame = smallFrame
            self.remoteVideoView?.alpha = 1
            self.view.sendSubviewToBack(videoView)
            let tmpVideoView: TEMRichVideoView! = self.remoteVideoView
            self.remoteVideoView = videoView
            self.remoteVideoView?.lblTitle!.hidden = false
            tmpVideoView.lblTitle!.hidden = false
        }
    }
    
    // MARK: Timer
    
    private func startTimer() {
        lblTime.text = "00:00:00"
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "increaseTimerCount", userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        lblTime.text = ""
        timerCount = 0
    }
    
    func increaseTimerCount() {
        let h: UInt = UInt(++timerCount/3600)
        let m: UInt = UInt((timerCount/60)%60)
        let s: UInt = UInt(timerCount%60)
        lblTime.text = String(format: "%lu:%02lu:%02lu", h, m, s)
    }
    
    // MARK: Toast
    
    private func showToast(message: String) {
        if toastTimer != nil {
            toastTimer?.invalidate()
        }
        lblToast.text = message
        lblToast.alpha = 1.0
        toastTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "hideToast", userInfo: nil, repeats: false)
    }
    
    func hideToast() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.lblToast.alpha = 0.0
        }) { completed -> Void in
            self.lblToast.text = ""
            self.toastTimer?.invalidate()
        }
    }
    
    // MARK: Control
    
    private func showControlView() {
        if controlViewTimer != nil {
            controlViewTimer?.invalidate()
        }
        controlView.alpha = 1.0
        if volumeView != nil {
            volumeView?.alpha = 1.0
        }
        controlViewTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "hideControlView", userInfo: nil, repeats: false)
    }
    
    func hideControlView() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.controlView.alpha = 0.0
            self.volumeView?.alpha = 0.0
            }) { completed -> Void in
                self.lblToast.text = self.lblToast.text
                self.controlViewTimer?.invalidate()
        }
    }
    
    // MARK: ProgressView
    
    private func addProgressView(remotePeerId: String) {
        for videoView in remoteVideoViewArray {
            if remotePeerId == videoView.ID {
                videoView.addProgressView()
                break
            }
        }
    }
    
    private func removeProgressView(remotePeerId: String) {
        for videoView in remoteVideoViewArray {
            if remotePeerId == videoView.ID {
                videoView.removeProgressView()
                break
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func closeTapped(sender: UIButton) {
        cleanUp()
        downTime = true
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.myConnection?.disconnect()
            self.myConnection = nil
        })
    }

    @IBAction func showControl(sender: UIControl) {
        let config: SKYLINKConnectionConfig! = (UIApplication.sharedApplication().delegate as! AppDelegate).appConfig
        if config.audio {
            showControlView()
        }
    }
    
    @IBAction func switchCameraTapped(sender: ControlButton) {
        myConnection?.switchCamera()
    }
    
    @IBAction func videoTapped(sender: ControlButton) {
        if sender.myState == 0 {
            sender.setImage(UIImage(named: "enable_camera"), forState: UIControlState.Normal)
            sender.myState = 1
            myConnection?.muteVideo(true)
        } else {
            sender.setImage(UIImage(named: "disable_camera"), forState: UIControlState.Normal)
            sender.myState = 0
            myConnection?.muteVideo(false)
        }
    }
    
    @IBAction func audioTapped(sender: ControlButton) {
        if sender.myState == 0 {
            sender.setImage(UIImage(named: "enable_audio"), forState: UIControlState.Normal)
            sender.myState = 1
            myConnection?.muteAudio(true)
        } else {
            sender.setImage(UIImage(named: "disable_audio"), forState: UIControlState.Normal)
            sender.myState = 0
            myConnection?.muteAudio(false)
        }
    }
    
    @IBAction func lockTapped(sender: ControlButton) {
        if sender.myState == 0 {
            sender.setImage(UIImage(named: "unlock"), forState: UIControlState.Normal)
            sender.myState = 1
            myConnection?.lockTheRoom()
        } else {
            sender.setImage(UIImage(named: "lock"), forState: UIControlState.Normal)
            sender.myState = 0
            myConnection?.unlockTheRoom()
        }
    }
}
