//
//  TEMVideoView.swift
//  SampleAppSwift
//
//  Created by macbookpro on 08/05/2015.
//  Copyright (c) 2015 Temasys Communications. All rights reserved.
//

import UIKit

protocol TEMVideoViewDelegate {
    
    func videoViewIsTapped(videoView : TEMVideoView)
    
}

class TEMVideoView: UIView {

    var delegate: TEMVideoViewDelegate?
    
    private var renderSize: CGSize?
    
    private weak var renderView: UIView?
    private weak var glassButton: UIButton?
    
    static func initialize(videoView: TEMVideoView, renderView: UIView) {
        renderView.frame = videoView.bounds
        renderView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        renderView.setTranslatesAutoresizingMaskIntoConstraints(true)
        videoView.addSubview(renderView)
        videoView.renderView = renderView
        
        var button: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        button.frame = CGRectMake(0, 0, videoView.bounds.size.width, videoView.bounds.size.height);
        button.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        button.setTranslatesAutoresizingMaskIntoConstraints(true)
        button.addTarget(videoView, action: "videoViewIsTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        videoView.addSubview(button)
        videoView.glassButton = button
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, videoView: UIView) {
        super.init(frame: frame)
        TEMVideoView.initialize(self, renderView: videoView)
        renderSize = CGSizeZero;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (renderView != nil && (renderSize?.height > 0 && renderSize?.width > 0)) {
            let defaultAspectRatio: CGSize = CGSizeMake(4, 3)
            let aspectRatio: CGSize! = CGSizeEqualToSize(renderSize!, CGSizeZero) ? defaultAspectRatio : renderSize
            let videoFrame: CGRect = AVMakeRectWithAspectRatioInsideRect(aspectRatio, self.bounds)
            self.renderView?.frame = videoFrame
            self.glassButton?.frame = videoFrame
        }
    }

    func layoutSubviews(size: CGSize) {
        renderSize = CGSizeEqualToSize(size, CGSizeZero) ? renderSize : size
        self.setNeedsLayout()
    }

    func getRenderSurface() -> UIView {
        return renderView!
    }

    func getTouchSurface() -> UIView {
        return glassButton!
    }
    
    @IBAction func videoViewIsTapped(sender: UIButton) {
        if (self.delegate != nil) {
            self.delegate?.videoViewIsTapped(self)
        }
    }

}
