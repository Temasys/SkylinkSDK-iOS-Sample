//
//  MessagesViewController.swift
//  Sample_App
//
//  Created by Phyo Pwint  on 12/4/16.
//  Copyright © 2016 Temasys . All rights reserved.
//

import UIKit
import AVFoundation


class MessagesViewController: UIViewController,SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate, UITextFieldDelegate  {
    
    //Declaring the Elements
    
    let ROOM_NAME = "MESSAGES-ROOM"
    var messages : NSMutableArray!
    var peers : NSMutableDictionary!
    var skylinkConnection: SKYLINKConnection!
    var skylinkApiKey: String!
    var skylinkApiSecret: NSString!
    var topView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var peersButton: UIButton!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTypeSegmentControl: UISegmentedControl!
    @IBOutlet weak var isPublicSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nicknameTextField.delegate = self
        messageTextField.delegate = self
        NSLog("SKYLINKConnection version = %@", SKYLINKConnection.getSkylinkVersion())
        self.title = "Messages"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel.png"), style: .Plain, target: self, action: #selector(MessagesViewController.disConnect))
        let infoButton: UIButton = UIButton(type: .InfoLight)
        infoButton.addTarget(self, action: #selector(MessagesViewController.showInfo), forControlEvents: .TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        self.messages = []
        self.peers = [:]
        self.updatePeersButtonTitle()
        //Creating configuration
        let config:SKYLINKConnectionConfig = SKYLINKConnectionConfig()
        config.video = false
        config.audio = false
        config.fileTransfer = false
        config.dataChannel = true // for data chanel messages
        
        // Creating SKYLINKConnection
        self.skylinkConnection = SKYLINKConnection(config: config, appKey: self.skylinkApiKey! as String)
        self.skylinkConnection.lifeCycleDelegate = self
        self.skylinkConnection.messagesDelegate = self
        self.skylinkConnection.remotePeerDelegate = self
        
        // Connecting to a room
        SKYLINKConnection.setVerbose(true)
        self.skylinkConnection.connectToRoomWithSecret(self.skylinkApiSecret! as String, roomName: ROOM_NAME, userInfo: nil)
        
    }
    
    func disConnect() {
        if (self.skylinkConnection != nil) {
            self.skylinkConnection.disconnect({() -> Void in
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
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
    func connection(connection: SKYLINKConnection, didConnectWithMessage errorMessage: String, success isSuccess: Bool) {
        if isSuccess {
            NSLog("Inside %@", #function)
            
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.messageTextField.enabled = true
                self.messageTextField.hidden = false
                self.nicknameTextField.enabled = true
                self.nicknameTextField.hidden = false
                self.sendButton.enabled = true
                self.sendButton.hidden = false
                self.messageTextField.becomeFirstResponder()
            })
            
        }
        else {
            let msgTitle: String = "Connection failed"
            let msg: String = errorMessage
            AlertMessage(msgTitle, msg:msg)
            self.disConnect()
        }
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            self.activityIndicator.stopAnimating()
        })
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
        let displayNickName: String = (userInfo.isKindOfClass(NSDictionary) &&
            userInfo["nickname"] != nil) ? userInfo["nickname"] as! String : "ID: \(peerId)"
        self.peers.addEntriesFromDictionary([peerId:displayNickName])
        self.updatePeersButtonTitle()
    }
    
    func connection(connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String, peerId: String) {
        self.peers.removeObjectForKey(peerId)
        self.updatePeersButtonTitle()
    }
    
    func connection(connection: SKYLINKConnection, didReceiveUserInfo userInfo: AnyObject, peerId: String) {
        self.peers.removeObjectForKey(peerId)
        let displayNickname: String = ((userInfo["nickname"]) != nil) ? userInfo["nickname"] as! String : "ID: \(peerId)"
        self.peers.addEntriesFromDictionary([peerId:displayNickname])
        self.updatePeersButtonTitle()
        self.tableView.reloadData()
    }
    
    // MARK: SKYLINKConnectionMessagesDelegate
    
    func connection(connection: SKYLINKConnection!, didReceiveCustomMessage message: AnyObject, `public` isPublic: Bool, peerId: String) {
        self.messages.insertObject(
            [   "message": message,
                "isPublic": isPublic,
                "peerId":peerId,
                "type":"signaling server"],
            atIndex : 0)
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
    }
    
    func connection(connection: SKYLINKConnection!, didReceiveDCMessage message: AnyObject, `public` isPublic: Bool, peerId: String!) {
        self.messages.insertObject(
            [   "message": message,
                "isPublic": isPublic,
                "peerId":peerId,
                "type":"P2P"],
            atIndex : 0)
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        
    }
    
    func connection(connection: SKYLINKConnection!, didReceiveBinaryData data: NSData, peerId: String) {
        let maybeString: AnyObject = String(data: data, encoding: NSUTF8StringEncoding)!
        
        self.messages.insertObject(["message": ((maybeString is NSString)) ? (String(maybeString)) : "Binary data of length \(UInt(data.length))", "isPublic": false, "peerId": peerId, "type": "binary data"], atIndex: 0)
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        
    }
    
    // MARK:  - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("messageCell")!
        var message: [NSObject : AnyObject] = (self.messages.objectAtIndex(indexPath.row)) as! [NSObject : AnyObject]
        cell.textLabel!.text = message["message"] as? String
        let equalStr: String = self.skylinkConnection.myPeerId
        
        if((message["peerId"] as! String) == equalStr) {
            cell.detailTextLabel!.text = (message["isPublic"] as! Bool) ? "Sent to all" : "Sent privately"
            cell.backgroundColor = UIColor(red: 0.71, green: 1, blue: 0.5, alpha: 1)
        }
        else {
            cell.detailTextLabel!.text = String(format:"From \(peers[message["peerId"] as! String]!) via \(message["type"] as! String) • \(message["isPublic"] as! Bool ? "Public" : "Private")")
            cell.backgroundColor = UIColor.whiteColor()
        }
        return cell
    }
    
    // MARK: Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var message: [NSObject : AnyObject] = self.messages.objectAtIndex(indexPath.row) as! [NSObject : AnyObject]
        let messageDetails: String = String(format:"Message \n %@ \n\n From: \n %@ \n\n %@", message["message"] as! String, (message["peerId"] as! String) == (self.skylinkConnection.myPeerId as String) ? "me" : (message["peerId"] as! String) ,message["isPublic"] as! Bool ? "Public" : "Private")
        let msgTitle: String = "Message Details"
        let msg: String = messageDetails
        AlertMessage(msgTitle, msg: msg)
    }
    
    // MARK: - Utils
    func processMessage() {
        if(self.isPublicSwitch.on && self.messageTypeSegmentControl.selectedSegmentIndex == 2) {
            let msgTitle: String = "Binary data is private."
            let msg: String = "\nTo send your message as binary data, uncheck the \"Public\" UISwitch."
            AlertMessage(msgTitle, msg: msg)
            self.hideKeyboardIfNeeded()
        }
        else if self.messageTextField.text!.characters.count > 0 {
            let message: String = self.messageTextField.text!
            if !(self.isPublicSwitch.on) {
                if self.peers.count != 0 {
                    let alert = UIAlertController(title: "Choose a private recipient.", message: "\nYou're about to send a private message\nWho do you want to send it to ?", preferredStyle: .Alert)
                    
                    let noAction = UIAlertAction(title: "Cancel", style: .Default) { (action) -> Void in
                    }
                    for peerDicKey in self.peers.allKeys as! [String] {
                        let yesAction = UIAlertAction(title: self.peers[peerDicKey] as? String, style: .Default) { (action) -> Void in
                            self.sendMessage(message, forPeerId: peerDicKey)
                        }
                        alert.addAction(yesAction)
                    }
                    alert.addAction(noAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    let msgTitle: String = "No peer connected."
                    let msg: String = "\nYou can't define a private recipient since there is no peer connected."
                    AlertMessage(msgTitle, msg: msg)
                }
                
                
            }
            else {
                
                self.sendMessage(message, forPeerId: nil)
            }
        }
        else {
            let msgTitle: String = "Empty message"
            let msg: String = "\nType the message to be sent."
            AlertMessage(msgTitle, msg: msg)
            
        }
        
    }
    
    func sendMessage(message: String, forPeerId peerId: String?) {
        var showSentMessage: Bool = true
        switch(self.messageTypeSegmentControl.selectedSegmentIndex){
        case 0 :
            self.skylinkConnection.sendDCMessage(message, peerId: peerId)
            NSLog("Finish DCMessage")
            break;
        case 1 :
            self.skylinkConnection.sendCustomMessage(message, peerId: peerId)
            break;
        case 2 :
            do {
                if(peerId != nil) {
                    try self.skylinkConnection.sendBinaryData(message.dataUsingEncoding(NSUTF8StringEncoding), peerId: peerId)
                }
            } catch let e as NSError {
                var message: String = "\(e)"
                if(e.localizedDescription == "Sending binary data in a MCU connection is not supported") {
                    message = message.stringByAppendingString("MCU can be enabled/disabled in Key configuration on the developer portal: http://developer.temasys.com.sg/")
                }
                let msgTitle: String = "Exeption when sending binary data"
                let msg: String = message
                AlertMessage(msgTitle, msg: msg)
                showSentMessage = false
            }
            break;
            
        default : break;
            
        }
        
        if(showSentMessage) {
            self.messageTextField.text = ""
            self.messages.insertObject(
                ["message": message,
                    "isPublic": NSNumber(bool: (peerId == nil)),
                    "peerId": self.skylinkConnection.myPeerId],
                atIndex: 0)
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation .Fade)
        }
        else {
            self.hideKeyboardIfNeeded()
        }
    }
    
    
    func updatePeersButtonTitle() {
        let peersCount: Int = self.peers.count
        if(peersCount == 0) {
            self.peersButton.setTitle("No Peer", forState: .Normal)
        }
        else {
            self.peersButton.setTitle("\(peersCount) peer" + (peersCount > 1 ? "s " : ""), forState: .Normal)
        }
    }
    
    func updateNickname() {
        if (self.nicknameTextField.text!.characters.count > 0) {
            self.skylinkConnection.sendUserInfo(["nickname" : self.nicknameTextField.text!])
        }
        else {
            let msgTitle: String = "Empty nickname"
            let msg: String = "\nType the nickname to set."
            AlertMessage(msgTitle, msg: msg)
        }
    }
    
    func hideKeyboardIfNeeded() {
        self.messageTextField.resignFirstResponder()
        self.nicknameTextField.resignFirstResponder()
    }
    
    // MARK: - UITextField delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.isEqual(self.nicknameTextField) {
            self.updateNickname()
        }
        else if textField.isEqual(self.messageTextField) {
            self.processMessage()
        }
        self.hideKeyboardIfNeeded()
        return true
    }
    
    // MARK: IBFuction
    @IBAction func sendTap(sender: UIButton) {
        self.processMessage()
    }
    
    @IBAction func dismissKeyboardTap(sender: UIButton) {
        self.hideKeyboardIfNeeded()
    }
    
    @IBAction func peersTap(sender: UIButton) {
        let msgTitle:String = sender.titleLabel!.text!
        let msg:String = self.peers.description
        AlertMessage(msgTitle, msg: msg)
    }
}
