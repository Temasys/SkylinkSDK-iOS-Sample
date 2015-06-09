//
//  ViewController.swift
//  SampleAppSwift
//
//  Created by macbookpro on 26/02/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var ctrlControls: UIControl!
    @IBOutlet weak var txtDisplayName: UITextField!
    @IBOutlet weak var txtRoomName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    // MARK: - UIKeyboardDidShowNotification
    
    func keyboardDidShow (notification: NSNotification) {        
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
            let ctrlY: CGFloat = CGRectGetMaxY(ctrlControls.frame)
            let keyboardY: CGFloat! = keyboardFrame?.origin.y
            let deltaY: CGFloat = ctrlY - keyboardY
            if deltaY > 0 {
                UIView.animateWithDuration(animationDuration!, animations: { () -> Void in
                    self.ctrlControls.frame = CGRectMake(self.ctrlControls.frame.origin.x, self.ctrlControls.frame.origin.y - deltaY, self.ctrlControls.frame.size.width, self.ctrlControls.frame.size.height)
                })
            }
        }
    }

    // MARK: - IBAction
    
    @IBAction func viewTapped(sender: UIControl) {
        self.view.endEditing(true)
    }
    
    @IBAction func joinTapped(sender: UIButton) {
        let displayName: String = txtDisplayName.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let roomName: String = txtRoomName.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if count(displayName) == 0 {
            self.view.endEditing(true)
            showAlert("Display Name is missing")
            return
        }
        
        if count(roomName) == 0 {
            self.view.endEditing(true)
            showAlert("Room Name is missing")
            return
        }
        
        let roomViewController: RoomViewController = RoomViewController(displayName: displayName, roomName: roomName)
        self.presentViewController(roomViewController, animated: true, completion: nil)
        (UIApplication.sharedApplication().delegate as! AppDelegate).roomViewController = roomViewController
    }

    // MARK: - private methods
    
    func showAlert(message: String) {
        let controller = UIAlertController(title: message,
            message:nil, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK",
            style: .Default, handler: nil)
        controller.addAction(okAction)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - deinit
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}

