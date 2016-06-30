//
//  HomeViewController.swift
//  Sample_App
//
//  Created by Phyo Pwint  on 5/4/16.
//  Copyright © 2016 Temasys . All rights reserved.
//

import UIKit

class HomeViewController: UIViewController,UITextFieldDelegate {
    
    
    
    //
    // ====== SET YOUR SKYLINK API KEY & SECRET HERE ======
    //
    let SKYLINK_APP_KEY: String = ""
    let SKYLINK_SECRET: String  = ""
    // Enroll at developer.temasys.com.sg if needed
    
    
    
    
    @IBOutlet weak var secretTextField: UITextField!
    @IBOutlet weak var keyTextField: UITextField!

    let USERDEFAULTS_KEY_SKYLINK_APP_KEY: String = "SKYLINK_APP_KEY"
    let USERDEFAULTS_KEY_SKYLINK_SECRET: String  = "SKYLINK_SECRET"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.keyTextField.text = SKYLINK_APP_KEY
        self.secretTextField.text = SKYLINK_SECRET
 
        if !(SKYLINK_APP_KEY.isEmpty) && !(SKYLINK_SECRET.isEmpty) {
            let defaultKey: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(USERDEFAULTS_KEY_SKYLINK_APP_KEY)
            let defaultSecret: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(USERDEFAULTS_KEY_SKYLINK_SECRET)
            
            if (defaultKey != nil) {
                self.keyTextField.text = defaultKey as? String
            }
            if (defaultSecret != nil) {
                self.secretTextField.text = defaultSecret as? String
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        let shouldPerform: Bool = (keyTextField.text?.characters.count == 36 && secretTextField.text?.characters.count == 13)
        
        if !shouldPerform {
            
            let msgTitle: String = "Wrong Key / Secret"
            
            let msg: String = "\nYou haven't correctly set your \nSkylink API Key (36 characters) or Secret (13 characters)\n\nIf you don't have access to the API yet, enroll at \ndeveloper.temasys.com.sg/register"
            
            let alertController = UIAlertController(title: msgTitle , message: msg, preferredStyle: .Alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
            
            alertController.addAction(OKAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            // SharedPrefrences
            NSUserDefaults.standardUserDefaults().setObject(self.keyTextField.text!, forKey: USERDEFAULTS_KEY_SKYLINK_APP_KEY)
            NSUserDefaults.standardUserDefaults().setObject(self.secretTextField.text!, forKey: USERDEFAULTS_KEY_SKYLINK_SECRET)
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
        return shouldPerform
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.respondsToSelector(Selector("setSkylinkApiKey:")) && segue.destinationViewController.respondsToSelector(Selector("setSkylinkApiSecret:")) {
            
            segue.destinationViewController.performSelector(Selector("setSkylinkApiKey:"),withObject: self.keyTextField.text!)
            segue.destinationViewController.performSelector(Selector("setSkylinkApiSecret:"),withObject: self.secretTextField.text!)
        }
    }
    
    func AlertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true) {
        }
    }
   
    //IBAction
    @IBAction func homeInfoTap(sender: UIButton) {
        let msgTitle:String = "HomeViewController"
        let msg: String = "\nSet you Skylink API Key and secret in the appropriate text field or modify HomeViewController's code to have it by default.\nIf you don't have your Key/Secret, enroll at developer.temasys.com.sg/register\n\nIn all view controllers, you can tap the info button in the upper right corner to get the current room name, your current local ID, the current API key and the current SDK version. Refer to the documentation for more infos on how to use it.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func videoCallVCinfoTap(sender: UIButton) {
        let msgTitle:String = "VideoCallViewController"
        let msg: String = "\nOne to one video call sample\n\nThe first 2 people to enter the room will be able to have a video call. The bottom bar contains buttons to refresh the peer connexion, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func multiVideoCallVCinfoTap(sender: UIButton) {
        let msgTitle:String = "MultiViewController"
        let msg: String = "\nThe first 4 people to enter the room will be able to have a multi party video call (as long as the room isn't locked). The bottom bar contains buttons to change the aspect of the peer video views, lock/unlock the room, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func audioCallVCinfoTap(sender: UIButton) {
        let msgTitle:String = "AudioCallViewController"
        let msg: String = "\nEnter the room to make an audio call with the other peers inside the same room. Tap the button on top to mute/unmute your microphone.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func messagesVCinfoTap(sender: UIButton) {
        let msgTitle:String = "MessagesViewController"
        let msg: String = "\nEnter the room to chat with the peers in the same room. The first text field allows you to edit your nickname, the yellow button indicates the number of peers in the room: tap it to display theirs ID and nickname if available, tap the icon to hide the keyboard if needed. There is also a button to select the type of messages you want to test (P2P, signeling server or binary data), and another one to choose if you want to send your messages to all the peers in the room (public) or privatly. If not public, you will be ask what peer you want to send your private message to when tapping the send button. To send a message, enter it in the second text field and tap the send button. The messages you sent appear in green.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func fileTransferVCinfoTap(sender: UIButton) {
        let msgTitle:String = "FileTransferViewController"
        let msg: String = "\nEnter the room to send file to the ppers in the same room. To send a file to all the peers, tap the main button, to send it to a particular peer, tap the peer in the list. In both cases you will be asked the king of media you want to send and to pick it if needed.\nBehaviour will be slightly different with MCU enabled.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        AlertMessage(msgTitle, msg: msg)
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        keyTextField.resignFirstResponder()
        secretTextField.resignFirstResponder()
        return true
    }
    
}

