//
//  FileTransferViewController.swift
//  Sample_App
//
//  Created by HEZHAO on 16/4/13.
//  Copyright © 2016 Temasys . All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import AssetsLibrary
import MobileCoreServices
import Photos
import AVFoundation

class FileTransferViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionFileTransferDelegate, SKYLINKConnectionRemotePeerDelegate, MPMediaPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let ROOM_NAME = "FILE-TRANSFER-ROOM"
    
    var alerts : [UIAlertController] = []
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var peersTableView: UITableView!
    @IBOutlet weak var fileTransferTableView: UITableView!
    
    // Other properties
    var skylinkConnection:SKYLINKConnection!
    var remotePeerArray: [String] = [] // array holding the ids (strings) of the peers connected to the room
    var transfersArray:NSMutableArray = []// array of dictionnaries holding infos about started (and finished) file transfers
    var musicPlayer: AVAudioPlayer? = AVAudioPlayer()
    
    var selectedRow:NSNumber = -1
    var skylinkApiKey:NSString!;
    var skylinkApiSecret:NSString!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.title = "File transfer";
        self.remotePeerArray = [String]()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Cancel.png"), style: .Plain, target: self, action: #selector(FileTransferViewController.disconnect))
        let infoButton: UIButton = UIButton(type: UIButtonType.InfoLight)
        infoButton.addTarget(self, action: #selector(FileTransferViewController.showInfo), forControlEvents: .TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
       
        // Creating configuration
        let config:SKYLINKConnectionConfig = SKYLINKConnectionConfig()
        config.video = false
        config.audio = false
        config.fileTransfer = true
        config.timeout = 30;
        config.dataChannel = true
        // Creating SKYLINKConnection
        self.skylinkConnection = SKYLINKConnection(config: config, appKey: self.skylinkApiKey! as String)
        self.skylinkConnection.lifeCycleDelegate = self
        self.skylinkConnection.fileTransferDelegate = self
        self.skylinkConnection.remotePeerDelegate = self
        // Connecting to a room
        SKYLINKConnection.setVerbose(true)
        
        self.skylinkConnection.connectToRoomWithSecret(self.skylinkApiSecret! as String, roomName: ROOM_NAME, userInfo: nil)
        NSLog("\(config.description)")
    }
    
    func disconnect(){
        if self.skylinkConnection != nil {
            self.skylinkConnection.disconnect({
                NSLog("viewControllers before:\(self.navigationController!.viewControllers)")
                self.navigationController?.popViewControllerAnimated(true)
                NSLog("viewControllers after:\(self.navigationController!.viewControllers)")
            })
        }
    }
    
    func showInfo(){
        let infosAlert: UIAlertController = UIAlertController(title: "\(NSStringFromClass(FileTransferViewController.self)) infos", message: "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(self.skylinkConnection.myPeerId)\n\nKey: •••••\(self.skylinkApiKey.substringFromIndex((self.skylinkApiKey as String).characters.count-7))\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())", preferredStyle: .Alert)
        alerts.append(infosAlert)
        showAlert()
    }
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        var title: String = ""
        
        
        if tableView.isEqual(self.peersTableView) {
            if section == 0 {
                title = (self.remotePeerArray.count > 0) ? "Or select a connected peer recipient:" : "No peer connected yet"
            }
        } else if tableView.isEqual(self.fileTransferTableView) {
            title = NSString(format: "File transfers (%lu)", CUnsignedLong(self.transfersArray.count)) as String
        }
        return title
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection scetion: Int) -> Int{

        var rowCount: NSInteger = 0
        if tableView.isEqual(self.peersTableView) {
            rowCount = self.remotePeerArray.count
        } else if tableView.isEqual(self.fileTransferTableView) {
            rowCount = self.transfersArray.count
        }
        return rowCount
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell: UITableViewCell = UITableViewCell()
        if tableView.isEqual(self.peersTableView) {
            cell = tableView.dequeueReusableCellWithIdentifier("peerCell")!
            cell.textLabel!.text = "Peer \(Int(indexPath.row) + 1), ID: \(self.remotePeerArray[indexPath.row])"
        } else if tableView.isEqual(self.fileTransferTableView) {
            cell = tableView.dequeueReusableCellWithIdentifier("fileTransferCell")!
            let trInfos: NSDictionary = self.transfersArray.objectAtIndex(indexPath.row) as! NSDictionary
            cell.textLabel?.text = NSString(format: "%@ %.0f%% • %@", (trInfos["isOutgoing"]?.boolValue! != false) ? "⬆️" : "⬇️", (trInfos["percentage"]?.floatValue)! * 100, trInfos["state"] as! String) as String
            cell.detailTextLabel?.text = NSString(format: "File: %@ • Peer: %@", trInfos["filename"] as! String, trInfos["peerId"] as! String) as String
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if tableView.isEqual(self.peersTableView) && view.isKindOfClass(UITableViewHeaderFooterView) {
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.lightGrayColor()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        
        if tableView.isEqual(self.peersTableView) {
            self.selectedRow = Int(indexPath.row)
            self.showTransferFormForRecipient(self.remotePeerArray[indexPath.row])
        } else if tableView.isEqual(self.fileTransferTableView) {
            let transferInfos: NSDictionary = self.transfersArray[indexPath.row] as! NSDictionary
            if (transferInfos["state"]!.isEqualToString("In progress")) {
               
                let alert: UIAlertController = UIAlertController(title: "Cancel file transfer ?", message: "\nCancel file transfer for filename:\n'\(transferInfos["filename"])'\npeer ID:\n\(transferInfos["peerId"])", preferredStyle: .Alert)
                let dropTrans: UIAlertAction = UIAlertAction(title: "Drop transfer", style: .Default){ action in
                   
                    NSLog("\(self.transfersArray[indexPath.row]["state"])")
                    NSLog("\(self.transfersArray[indexPath.row]["state"]!!)")
                    
                    if (self.transfersArray[indexPath.row]["state"]!!.isEqualToString("In progress")) {
                        self.skylinkConnection.cancelFileTransfer(transferInfos["filename"] as! String, peerId: transferInfos["peerId"] as! String)
                        self.updateFileTranferInfosForFilename(transferInfos["filename"] as? String!, peerId: transferInfos["peerId"] as? String!, withState: "Cancelled", progress: transferInfos["progress"] as! Float!, isOutgoing: transferInfos["isOutgoing"] as! NSInteger!)
                    } else {
                        let canNotCancelAlert = UIAlertController(title: "Can not cancel", message: "Transfer already completed", preferredStyle: .Alert)
                        self.alerts.append(canNotCancelAlert)
                        self.showAlert()
                    }
                }
                alert.addAction(dropTrans)
                let cancelBtn: UIAlertAction = UIAlertAction(title: "Continue transfer", style: .Cancel){ action in }
                alert.addAction(cancelBtn)
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else {
                let alert = UIAlertController(title: "Transfer details", message: transferInfos.description, preferredStyle: .Alert)
                alerts.append(alert)
                self.showAlert()
            }
        }
    }
    
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        var peerId: String! = nil
        if self.selectedRow != -1 && Int(self.selectedRow.intValue) < self.remotePeerArray.count {
            peerId = self.remotePeerArray[Int(self.selectedRow.intValue)]
        }
        self.startFileTransfer(peerId, url: info[UIImagePickerControllerReferenceURL] as? NSURL, type: SKYLINKAssetTypePhoto)
    }
    
    
    // MARK: - MPMediaPickerControllerDelegate
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismissViewControllerAnimated(true, completion: nil)
        var peerId: String? = nil
        if self.selectedRow != -1 && Int(self.selectedRow.intValue) < self.remotePeerArray.count {
            peerId = self.remotePeerArray[Int(self.selectedRow.intValue)]
        }
        self.startFileTransfer(peerId, url: mediaItemCollection.representativeItem?.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL, type: SKYLINKAssetTypeMusic)
    }
    
    
    // SKYLINK Delegate methods implementations
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    
    func connection(connection: SKYLINKConnection, didConnectWithMessage errorMessage: String, success isSuccess: Bool) {
        self.activityIndicator.stopAnimating()
        if isSuccess {
           NSLog("Connection success :D")
        }
        else {
            let alert: UIAlertController = UIAlertController(title: "Connection failed", message: errorMessage, preferredStyle: .Alert)
            let cancelAction=UIAlertAction(title: "OK", style: .Cancel){action->Void in}
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            self.navigationController!.popViewControllerAnimated(true)
        }
        
    }
    
    func connection(connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String) {
        let alert: UIAlertController = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .Alert)
        let cancelAction=UIAlertAction(title: "OK", style: .Cancel){action->Void in}
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true) {
            self.disconnect()
        }
    }
    
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    
    func connection(connection: SKYLINKConnection, didJoinPeer userInfo: AnyObject, mediaProperties pmProperties: SKYLINKPeerMediaProperties, peerId: String) {
        NSLog("Peer with id %@ joigned the room, properties: %@", peerId, pmProperties.description)
        self.remotePeerArray.append(peerId)
        self.peersTableView.reloadData()
    }
    
    func connection(connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String, peerId: String!) {
        NSLog("Peer with id %@ left the room with message: %@", peerId, errorMessage)
        if self.remotePeerArray.indexOf(peerId) != nil{
            self.remotePeerArray.removeAtIndex(self.remotePeerArray.indexOf(peerId)!)
        }
        
        self.peersTableView.reloadData()
    }
    
    // MARK: - SKYLINKConnectionFileTransferDelegate
    
    func connection(connection: SKYLINKConnection, didReceiveRequest filename: String, peerId: String) {
        
        let alert: UIAlertController = UIAlertController(title: "Accept file transfer ?", message: "\nA user wants to send you a file named:\n'\(filename)'", preferredStyle: .Alert)
        let rejectAction=UIAlertAction(title: "Decline", style: .Default){action->Void in
            self.skylinkConnection.acceptFileTransfer(false, filename: filename, peerId: peerId)
           
            self.alerts.removeAtIndex(self.alerts.count - 1)
            self.showAlert()
        }
        alert.addAction(rejectAction)
        let acceptAction=UIAlertAction(title: "Accept", style: .Default){action->Void in
            self.skylinkConnection.acceptFileTransfer(true, filename: filename, peerId: peerId)
            
            self.alerts.removeAtIndex(self.alerts.count - 1)
            self.showAlert()
        }
        alert.addAction(acceptAction)
        alerts.append(alert)
        self.showAlert()
        
    }
    
    func connection(connection: SKYLINKConnection, didReceivePermission isPermitted: Bool, filename: String, peerId: String) {
        if !isPermitted {
            let alert: UIAlertController = UIAlertController(title: "File refused", message: "The peer ID: \(peerId) has refused your '\(filename)' file sending request", preferredStyle: .Alert)
            alerts.append(alert)
            self.showAlert()
        }
        else if filename != "" && peerId != ""{
            
        }
    }
    
    
    func connection(connection: SKYLINKConnection!, didUpdateProgress percentage: CGFloat, isOutgoing: Bool, filename: String!, peerId: String!) {
        self.updateFileTranferInfosForFilename(filename, peerId: ((peerId != nil) ? peerId : "all"), withState: "In progress", progress: NSNumber(float: Float(percentage)), isOutgoing: NSNumber(bool: isOutgoing))
    }
    
    
    func connection(connection: SKYLINKConnection, didDropTransfer filename: String, reason message: String!, isExplicit: Bool, peerId: String!) {
        self.updateFileTranferInfosForFilename(filename, peerId: ((peerId != nil) ? peerId : "all"), withState: (message != nil) ? message : "Dropped my sender", progress: nil, isOutgoing: nil)
        
        
        
    }
    
    func connection(connection: SKYLINKConnection, didCompleteTransfer filename: String, fileData: NSData, peerId: String!) {
        
        self.updateFileTranferInfosForFilename(filename, peerId: (peerId != nil) ? peerId : "all", withState: "Completed ✓", progress: 1, isOutgoing: nil)
        
        if fileData.length != 0 {
            let fileExtension: NSString = filename.componentsSeparatedByString(".").last!
            let filename1: String = filename.stringByReplacingOccurrencesOfString(" ", withString: "_")
            if self.isImage(fileExtension as String)==true && UIImage(data:fileData) != nil{
                UIImageWriteToSavedPhotosAlbum(UIImage(data:fileData)!, self, #selector(FileTransferViewController.image(_:didFinishSavingWithError:contextInfo:)),nil)
            } else if (fileExtension.isEqualToString("mp3") || fileExtension.isEqualToString("m4a")) {
                
                
                let showMusicAlert:(Void) throws ->Void = {
                    self.musicPlayer = try fileExtension.isEqualToString("mp3") ? AVAudioPlayer(data: fileData, fileTypeHint: AVFileTypeMPEGLayer3) : AVAudioPlayer(data: fileData)
                    self.musicPlayer!.play()
                    let alert: UIAlertController = UIAlertController(title: "Music transfer completed", message: "File transfer success.\nPEER: \(peerId)\n\nPlaying the received music file:\n'\(filename)'", preferredStyle: .Alert)
                    let cancelBtn: UIAlertAction = UIAlertAction(title: "Stop playing", style: .Default){ action in
                        self.musicPlayer!.stop()
                        self.musicPlayer = nil
                    }
                    alert.addAction(cancelBtn)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                do{
                    try showMusicAlert()
                } catch let error{
                    print("ERROR IN Music => \(error)")
                }
                
                
            }
            else {
                let pathArray: [AnyObject] = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                let filePath: String = pathArray.first!.stringByAppendingPathComponent(filename1)
                do{
                    let b: Bool = try self.removeFileAtPath(filePath)
                    if NSFileManager.defaultManager().fileExistsAtPath(filePath) && !b {
                        return
                    }
                }catch{
                    print("ERROR IN remove file => \(error)")
                }
                var wError: NSError?
                do{
                    try fileData.writeToFile(filePath, options: .AtomicWrite)
                }catch let exception{
                    wError = exception as NSError
                    NSLog("\(exception)")
                }
                if wError != nil {
                    NSLog("%s • Error while writing '%@'->%@", #function, filePath, wError!.localizedDescription)
                }
                else {
                    if self.isMovie(fileExtension as String) && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) {
                 
                        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(string: filePath)!, completionBlock: {(assetURL: NSURL!, error: NSError!) in
                            if error != nil {
                                NSLog("%s • Error while saving '%@'->%@", #function, filename1, error.localizedDescription)
                            }
                            else {
                                do{
                                    try self.removeFileAtPath(filePath)
                                }catch{
                                    print("Some error => \(error)")
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    
    // MARK: - other methods
    
    // Handle the stack of Alerts to be shown
    func showAlert() {
        if let alert = alerts.last {
            let okayAction = UIAlertAction(title: "OK", style: .Default) { action in
                self.alerts.removeAtIndex(self.alerts.count - 1)
                self.showAlert()
            }
            if self.alerts.count == 1 && alert.actions.count == 0{
                alert.addAction(okayAction)
                presentViewController(alert, animated: true, completion: nil)
            }
            else {
                self.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
                if alert.actions.count == 0 {
                    alert.addAction(okayAction)
                    presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    presentViewController(alert, animated: true, completion: nil)
                }
            }
            
        }
        else {
            print("All alerts shown")
        }
    }
    
    
    func updateFileTranferInfosForFilename(filename: String?, peerId: String?, withState state: String?, progress percentage: NSNumber?, isOutgoing: NSNumber?) {
        let indexOfTransfer = self.transfersArray.indexOfObjectPassingTest({ (obj, idx, stop) -> Bool in
            return ((obj as! NSDictionary)["filename"]?.isEqualToString(filename!))! && ((obj as! NSDictionary)["peerId"]?.isEqualToString(peerId!))!
        })
        
        if (indexOfTransfer != NSNotFound) {
            
            let transferInfos: NSMutableDictionary = NSMutableDictionary(dictionary: self.transfersArray[indexOfTransfer] as! [NSObject : AnyObject])
            if filename != nil{
                transferInfos.setObject(filename!, forKey: "filename")
                
            }
            if peerId != nil{
                transferInfos.setObject(peerId!, forKey: "peerId")
            }
            if isOutgoing != nil{
                transferInfos.setObject(isOutgoing!, forKey: "isOutgoing")
            }
            if percentage != nil{
                transferInfos.setObject(percentage!, forKey: "percentage")
            }
            if state != nil{
                transferInfos.setObject(state!, forKey: "state")
            }
            self.transfersArray.replaceObjectAtIndex(indexOfTransfer, withObject: transferInfos)
        }
            
        else {
            let object = NSDictionary(dictionary: ["filename" : (filename != nil) ? (filename! as String) : "none",
                "peerId" : (peerId != nil) ? (peerId! as String) : "No peer Id",
                "isOutgoing" : (isOutgoing != nil) ? (isOutgoing! as NSNumber) : NSNumber(bool:false),
                "percentage" : (percentage != nil) ? (percentage! as NSNumber) : NSNumber(int: (-0)),
                "state" : (state != nil) ? (state! as String) : "Undefined"])
            
            self.transfersArray.insertObject(object as AnyObject, atIndex: 0)
        }
        
        self.fileTransferTableView.reloadData()
        
    }
    
    
    func startFileTransfer(userId: String?, url fileURL: NSURL!, type transferType: SKYLINKAssetType) {
        
        if userId != nil && fileURL != nil {
            do {
                let triggerFileTransfer:(Void) throws ->Void = {
                    self.skylinkConnection.sendFileTransferRequest(fileURL, assetType: transferType, peerId: userId)
                }
                try triggerFileTransfer()
            }
            catch {
                
            }
        } else if fileURL != nil {
            // No peer ID provided means transfer to every peer in the room
            self.skylinkConnection.sendFileTransferRequest(fileURL, assetType: transferType)
        } else {
            let alert: UIAlertController = UIAlertController(title: "No file URL", message: "\nError: there is no file URL. Try another media.", preferredStyle: .Alert)
            alerts.append(alert)
            self.showAlert()
        }
    }
    
    func showTransferFormForRecipient(peerID: String!){
        var message: String
        if peerID != nil {
            message = "\nYou are about to send a tranfer request to user with ID \n\(peerID)\nWhat do you want to send ?"
        }else{
            message = "\nYou are about to send a tranfer request all users\nWhat do you want to send ?"
        }
        
        let alertPopUp:UIAlertController=UIAlertController(title:"Send a file.",message: message, preferredStyle: .Alert)
        let cancelAction=UIAlertAction(title: "Cancel", style: .Cancel){action->Void in}
        alertPopUp.addAction(cancelAction)
        let pVAction = UIAlertAction(title: "Photo / Video (pick from library)", style: .Default){action->Void in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
                let pickerController: UIImagePickerController = UIImagePickerController()
                pickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                pickerController.delegate = self
                pickerController.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
                self.presentViewController(pickerController, animated: true, completion: nil)
            }
        }
        alertPopUp.addAction(pVAction)
        let musicAction = UIAlertAction(title: "Music (pick from library)", style: .Default) { (Void) in
            let pickerController = MPMediaPickerController()
            pickerController.delegate = self
            self.presentViewController(pickerController, animated: true, completion: nil)
        }
        alertPopUp.addAction(musicAction)
        
        //Music
        let fileAction = UIAlertAction(title: "File (prepared image)", style: .Default){action -> Void in
            var peerId: String!
            if self.selectedRow != -1 && Int(self.selectedRow.intValue) < Int(self.remotePeerArray.count) {
                peerId = self.remotePeerArray[Int(self.selectedRow.intValue)]
            }
            let filePath: String! = NSBundle.mainBundle().pathForResource(((peerId != nil) ? "sampleImage_transfer" : "sampleImage_groupTransfer"), ofType: "png", inDirectory: "TransferFileSamples")
            if filePath != nil {
                self.startFileTransfer(peerId, url: NSURL(string: filePath), type: SKYLINKAssetTypeFile)
            }
            else {
                self.startFileTransfer(nil, url: nil, type: SKYLINKAssetTypeFile)
            }
        }
        alertPopUp.addAction(fileAction)
        self.presentViewController(alertPopUp, animated: true, completion: nil)
        
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController){
        // Dismiss the picker if the user canceled
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<Void>) {
        if error != nil {
            NSLog("%s • Error while saving '%@'->%@", #function, contextInfo, error!.localizedDescription)
            NSLog("%s • Now trying to save image in the Documents Directory", #function)
            let pathArray: [AnyObject] = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let filePath: String = pathArray.first!.stringByAppendingPathComponent(String(contextInfo))
            do{
                let b: Bool = try self.removeFileAtPath(filePath)
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) && !b {
                    return
                }
            }catch{
                print(error)
                return
            }
            var wError: NSError?
            do{
                try UIImagePNGRepresentation(image)?.writeToFile(filePath, options: .AtomicWrite)
            }catch let exception{
                wError = exception as NSError
                NSLog("Write to file exception => \(exception)")
            }
            if wError != nil {
                NSLog("%s • Error while writing '%@'->%@", #function, filePath, wError!.localizedDescription)
            }
        }else {
            NSLog("%s • Image saved successfully", #function)
        }
    }
    
    func removeFileAtPath(filePath: String) throws -> Bool{
        var succeed: Bool = false
        var error: NSError?
        
        do{
            try NSFileManager.defaultManager().removeItemAtPath(filePath)
        }catch let exception{
            error = exception as NSError
            NSLog("Write to file exception => \(exception)")
        }
        if error != nil {
            NSLog("%s • Error while removing '%@'->%@", #function, filePath, error!.localizedDescription)
        }
        else {
            succeed = true
        }
        return succeed
    }
    
    func isImage(exten: String) -> Bool {
        return ["jpg", "jpeg", "jpe", "jif", "jfif", "jfi", "jp2", "j2k", "jpf", "jpx", "jpm", "tiff", "tif", "pict", "pct", "pic", "gif", "png", "qtif", "icns", "bmp", "bmpf", "ico", "cur", "xbm"].contains(exten.lowercaseString)
    }
    
    
    func isMovie(exten: String) -> Bool {
        return ["mpg", "mpeg", "m1v", "mpv", "3gp", "3gpp", "sdv", "3g2", "3gp2", "m4v", "mp4", "mov", "qt"].contains(exten.lowercaseString)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func sendToAllTap(sender: AnyObject) {
        self.selectedRow = -1
        if self.remotePeerArray.count > 0 {
            self.showTransferFormForRecipient(nil)
        }
        else{
            let alert: UIAlertController = UIAlertController(title: "No peer connected", message: "Wait for someone to connect before sending files.", preferredStyle: .Alert)
            alerts.append(alert)
            showAlert()
        }
    }
    
    
}
