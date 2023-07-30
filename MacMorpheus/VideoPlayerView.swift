//
//  VideoPlayerView.swift
//  MacMorpheus
//
//  Created by Zakk Hoyt on 7/30/23.
//  Copyright © 2023 emoRaivis. All rights reserved.
//

import AppKit
import AVKit
import SceneKit

class SVideoPlayerViewProjectionMethod: NSObject {
    typealias EyeLayerHandler = (
        _ eyeLayer: CALayer,
        _ eye: Int,
        _ contentSize: CGSize,
        _ playerLayer: AVPlayerLayer,
        _ eyeView: SEyeView
    ) -> Void
    
    var name: String
    var eyeLayerHandler: EyeLayerHandler
    
    static var allProjectionMethods: [SVideoPlayerViewProjectionMethod] = {
        [
            SVideoPlayerViewProjectionMethod.projectionMethod(
                name: "2D 360° Regular",
                eyeLayerHandler: { eyeLayer, eye, contentSize, playerLayer, eyeView in
                    eyeLayer.frame = CGRect(origin: .zero, size: contentSize)
                    eyeView.projectionTransform = SCNMatrix4MakeRotation(.pi, 0, 1, 0)
                }
            ),
            SVideoPlayerViewProjectionMethod.projectionMethod(
                name: "3D 360° Horizontal (Stacked)",
                eyeLayerHandler: { eyeLayer, eye, contentSize, playerLayer, eyeView in
                    var eyeFrame = CGRect(origin: .zero, size: contentSize)
                    if eye == 1 {
                        eyeFrame.origin.y += eyeFrame.size.height
                    }
                    eyeLayer.frame = eyeFrame
                    eyeView.projectionTransform = SCNMatrix4MakeRotation(.pi, 0, 1, 0)
                }
            ),
            SVideoPlayerViewProjectionMethod.projectionMethod(
                name: "3D 180° Vertical (Side By Side)",
                eyeLayerHandler: { eyeLayer, eye, contentSize, playerLayer, eyeView in
                    var eyeFrame = CGRect(origin: .zero, size: contentSize)
                    if eye == 1 {
                        var playerFrame = playerLayer.frame
                        playerFrame.origin.x -= round(eyeFrame.size.width / 2.0)
                        playerLayer.frame = playerFrame
                    } else {
                        let maskLayer = CALayer()
                        maskLayer.backgroundColor = NSColor.red.cgColor  //[NSColor redColor].CGColor;
                        maskLayer.frame = CGRect(
                            origin: .zero,
                            size: CGSize(
                                width: contentSize.width / 2.0,
                                height: contentSize.height
                            )
                        )
                        playerLayer.mask = maskLayer
                    }
//                    eyeLayer.frame = eyeFrame
//                    eyeView.projectionTransform = SCNMatrix4MakeRotation(.pi, 0, 1, 0)
                }
            )
        ]
    }()
    
//    + (instancetype) projectionMethodWithName: (NSString *) name
//                              eyeLayerHandler: (void (^)(CALayer * eyeLayer, int eye, CGSize contentSize, AVPlayerLayer * playerLayer, EyeView * eyeView)) eyeLayerHandler;
    static func projectionMethod(
        name: String,
        eyeLayerHandler: @escaping EyeLayerHandler
    ) -> SVideoPlayerViewProjectionMethod {
        SVideoPlayerViewProjectionMethod(
            name: name,
            eyeLayerHandler: eyeLayerHandler
        )
    }
    
    init(
        name: String,
        eyeLayerHandler: @escaping EyeLayerHandler
    ) {
        self.name = name
        self.eyeLayerHandler = eyeLayerHandler
    }
}

class SVideoPlayerView: NSView {
    var url: URL?
//    var projectionMethod: SVideoPlayerViewProjectionMethod
    
    private var leftView: SEyeView
    private var rightView: SEyeView
    private var player: AVPlayer?
    
    override init(frame frameRect: NSRect) {
        
//        var r = self.bounds
        var r = frameRect
        
        r.size.width /= 2
        leftView = SEyeView(frame: r)
        leftView.autoresizingMask = [.width, .height, .maxXMargin]

        
        r.origin.x += r.size.width
        rightView = SEyeView(frame: r)
        rightView.autoresizingMask = [.width, .height, .maxXMargin]
        
        super.init(frame: frameRect)
        
        addSubview(leftView)
        addSubview(rightView)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(psvrDataReceivedNotification(note:)),
            name: .psvrDataReceivedNotification,
            object: SPSVR.shared
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func psvrDataReceivedNotification(note: NSNotification) {
        
    }
    
}
