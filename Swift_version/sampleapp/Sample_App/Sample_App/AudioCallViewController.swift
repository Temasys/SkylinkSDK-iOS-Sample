//
//  AudioCallViewController.swift
//  Sample_App
//
//  Created by HEZHAO on 16/4/12.
//  Copyright © 2016 Temasys . All rights reserved.
//
import UIKit
import Foundation

class AudioCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate {
    let ROOM_NAME: String = "AUDIO-CALL-ROOM"
    
    // IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var muteMicrophone: UIButton!
    //Other properties
    
    var skylinkConnection: SKYLINKConnection!
    var remotePeerArray: NSMutableArray = []
    
    var skylinkApiKey: String!
    var skylinkApiSecret: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Audio Call"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel.png"), style: .Plain, target: self, action: #selector(AudioCallViewController.disconnect))
        let infoButton:UIButton = UIButton(type: UIButtonType.InfoLight)
        infoButton.addTarget(self, action: #selector(AudioCallViewController.showInfo), forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        //Creating configuration
        let config: SKYLINKConnectionConfig = SKYLINKConnectionConfig()
        config.video = false
        config.audio = true
        //Creating SKYLINKConnection
        self.skylinkConnection = SKYLINKConnection(config: config, appKey: self.skylinkApiKey! as String)
        self.skylinkConnection.lifeCycleDelegate = self
        self.skylinkConnection.mediaDelegate = self
        self.skylinkConnection.remotePeerDelegate = self
        // Connecting to a room
        SKYLINKConnection.setVerbose(true)
        
        let credInfos: Dictionary = ["startTime": NSDate(), "duration": NSNumber(float: 24.0)]
        NSLog("This is credInfos \(credInfos.description)")
        //let credential = SKYLINKConnection.calculateCredentials(ROOM_NAME, duration: credInfos["duration"] as! String, startTime: credInfos["startTime"] as! NSDate, secret: self.skylinkApiSecret)
        let durationString = credInfos["duration"] as! NSNumber
        NSLog("This is Credential \(durationString)")
        let credential = SKYLINKConnection.calculateCredentials(ROOM_NAME, duration: durationString, startTime: credInfos["startTime"] as! NSDate, secret: self.skylinkApiSecret)
        skylinkConnection.connectToRoomWithCredentials(["credential": credential, "startTime": credInfos["startTime"]!, "duration": credInfos["duration"]!], roomName: ROOM_NAME, userInfo: "Audio call user #\(arc4random() % 1000) - iOS \(UIDevice.currentDevice().systemVersion)")
    }
    
    func disconnect(){
        if self.skylinkConnection != nil {
            self.skylinkConnection.disconnect({
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
    
    func showInfo(){
        let infosAlert: UIAlertController = UIAlertController(title: "\(NSStringFromClass(AudioCallViewController.self)) infos", message: "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(self.skylinkConnection.myPeerId)\n\nKey: •••••\(self.skylinkApiKey.substringFromIndex(self.skylinkApiKey.startIndex.advancedBy(self.skylinkApiKey.characters.count-7)))\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())", preferredStyle: .Alert)
        let cancelAction=UIAlertAction(title: "OK", style: .Cancel){action->Void in}
        infosAlert.addAction(cancelAction)
        self.presentViewController(infosAlert, animated: true, completion: nil)
        
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connection(connection: SKYLINKConnection!, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        if isSuccess {
            NSLog("Inside %s", #function)
        } else {
            let alert: UIAlertController = UIAlertController(title: "Connection failed", message: errorMessage, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel){action->Void in}
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
            self.muteMicrophone.enabled = true
        }
    }
    
    func connection(connection: SKYLINKConnection!, didDisconnectWithMessage errorMessage: String!) {
        let alert: UIAlertController = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .Alert)
        let cancelAction=UIAlertAction(title: "OK", style: .Cancel){action->Void in}
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: {
            self.disconnect()
        })
    }
    
    
    // MARK: - SKYLINKConnectionMediaDelegate
    func connection(connection: SKYLINKConnection!, didToggleAudio isMuted: Bool, peerId: String!) {
        let emurateArray: NSArray = self.remotePeerArray.copy() as! NSArray
        for peerDic in emurateArray {
            if peerDic["id"] as! String == peerId {
                self.remotePeerArray.removeObject(peerDic)
                self.remotePeerArray.addObject(["id": peerId, "isAudioMuted": Int(isMuted)])
            }
        }
        self.tableView.reloadData()
    }
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    func connection(connection: SKYLINKConnection!, didJoinPeer userInfo: AnyObject!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        NSLog("Peer with id %@ joigned the room.", peerId)
        self.remotePeerArray.addObject(
            ["id" : peerId,
                "isAudioMuted" : Int(pmProperties.isAudioMuted),
                "nickname" : userInfo is String ? userInfo : ""
            ])
        self.tableView.reloadData()
    }
    
    func connection(connection: SKYLINKConnection!, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        NSLog("Peer with id %@ left the room with message: %@", peerId, errorMessage)
        for peerDic in self.remotePeerArray {
            if peerDic["id"] as! String == peerId {
                self.remotePeerArray.removeObject(peerDic)
            }
        }
        self.tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "\(CUnsignedLong(self.remotePeerArray.count)) peer(s) connected"
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.remotePeerArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("ACpeerCell")!
        var peerDic: [NSObject : AnyObject] = self.remotePeerArray[indexPath.row] as! [NSObject : AnyObject]
        NSLog("PeerDic,id: \(String(peerDic["id"]!) )")
        cell.textLabel!.text = peerDic["nickname"] != nil ? peerDic["nickname"] as! String : "Peer \(indexPath.row + 1)"
        cell.detailTextLabel?.text = "ID: \(peerDic["id"]!) \(peerDic["isAudioMuted"]?.boolValue == true ? " - Audio muted" : "")"
        cell.backgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.00)

        return cell
    }
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indextPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indextPath, animated: true)
    }
    
    // MARK: - IBAction
    @IBAction func switchAudioTap(sender: AnyObject) {
        sender.setTitle(!self.skylinkConnection.isAudioMuted() ? "Unmute microphone" : "Mute microphone", forState: UIControlState.Normal)
        self.skylinkConnection.muteAudio(!self.skylinkConnection.isAudioMuted())
    }
    
    
}
