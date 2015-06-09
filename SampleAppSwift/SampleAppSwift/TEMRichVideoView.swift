//
//  TEMRichVideoView.swift
//  SampleAppSwift
//
//  Created by macbookpro on 08/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

import UIKit

class TEMRichVideoView: TEMVideoView {
    
    var ID: String = ""
    
    weak var lblTitle: UILabel?
    
    private weak var progressView: TEMProgressView?
    
    private var enabled: Bool = true
    private var remote: Bool = true
    
    static func richInitialize(videoView: TEMRichVideoView, renderView: UIView) {
        let selfSize: CGSize = videoView.bounds.size;
        var label: UILabel = UILabel(frame: CGRectMake(0, 0, selfSize.width, 21))
        label.textColor = UIColor.blueColor()
        label.textAlignment = NSTextAlignment.Left;
        label.numberOfLines = 1;
        label.autoresizingMask = UIViewAutoresizing.FlexibleWidth;
        label.setTranslatesAutoresizingMaskIntoConstraints(true)
        videoView.insertSubview(label, aboveSubview: renderView)
        videoView.lblTitle = label;
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, videoView: UIView) {
        super.init(frame: frame, videoView: videoView)
        TEMRichVideoView.richInitialize(self, renderView: videoView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var renderSurface: UIView = self.getRenderSurface()
        self.lblTitle?.frame = CGRectMake(renderSurface.frame.origin.x, renderSurface.frame.origin.y, renderSurface.frame.size.width, 21)
        if (self.progressView != nil) {
            let lblTitleFrame: CGRect! = self.lblTitle?.frame
            self.progressView?.frame = CGRectMake(lblTitleFrame.origin.x, CGRectGetMaxY(lblTitleFrame), lblTitleFrame.size.width, lblTitleFrame.size.height)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - public methods
    
    func addProgressView() {
        // Listen to the 'SKYLINKFileProgress' Notification.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gotProgress", name: "SKYLINKFileProgress", object: nil)
        let lblTitleFrame: CGRect! = self.lblTitle?.frame
        var progressView: TEMProgressView = TEMProgressView(frame: CGRectMake(lblTitleFrame.origin.x, CGRectGetMaxY(lblTitleFrame), lblTitleFrame.size.width, lblTitleFrame.size.height))
        self.insertSubview(progressView, aboveSubview: self.lblTitle!)
        self.progressView = progressView;
    }

    func removeProgressView() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.progressView?.removeFromSuperview()
        self.progressView = nil
    }
    
    // MARK: - properties
    
    func getTitle() -> String? {
        return self.lblTitle?.text
    }
    
    func setTitle(text: String) {
        self.lblTitle?.text = text
    }
    
    func isEnabled() -> Bool {
        return self.enabled
    }
    
    func setEnabled(enabled: Bool) {
        self.enabled = enabled
        if (self.enabled != enabled) {
            self.enabled = enabled;
            if (enabled) {
                self.getTouchSurface().alpha = 1.0
                self.getTouchSurface().backgroundColor = UIColor.clearColor()
            } else {
                self.getTouchSurface().alpha = 0.5
                self.getTouchSurface().backgroundColor = UIColor.lightGrayColor()
            }
        }
    }
    
    func isRemote() -> Bool {
        return self.remote
    }
    
    func setRemote(remote: Bool) {
        if (self.remote != remote) {
            self.remote = remote;
            if (remote) {
                self.getRenderSurface().transform = CGAffineTransformMakeScale(-1, 1)
            }
        }
    }
    
    // MARK: - private methods
    
    /**
    @discussion Update progress bar upon getting 'SKYLINKFileProgress' Notification.
    */
    func gotProgress(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let comparisonResult: NSComparisonResult = self.ID.caseInsensitiveCompare(userInfo["peerId"] as! String)
            if (comparisonResult == NSComparisonResult.OrderedSame) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progressView?.setPercentage(userInfo["percentage"] as! CGFloat)
                })
            }
        }
    }
    
}
