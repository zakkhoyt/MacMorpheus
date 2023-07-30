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



class SVideoPlayerView: NSView {
    var url: URL?
    var projectionMethod: SVideoPlayerViewProjectionMethod?
    
    private var leftView: SEyeView
    private var rightView: SEyeView
    private var player: AVPlayer?
    
    override init(frame frameRect: NSRect) {
        #warning("FIXME: @zakkhoyt - this might not work as is")
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
    
    func loadURL(
        movieURL url: URL,
        projectionMethod: SVideoPlayerViewProjectionMethod
    ) {
        guard player != nil else { return }
        self.url = url
        self.projectionMethod = projectionMethod
        
        let player = AVPlayer(url: url)
        player.addObserver(
            self,
            forKeyPath: "currentItem.presentationSize",
            options: [],
            context: nil
        )
        player.play()
        self.player = player
        
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let playerObject = object as? AVPlayer,
              playerObject == player else { return }
        guard keyPath == "currentItem.presentationSize" else { return }
        guard player?.status == .readyToPlay else { return }
        guard let contentSize = player?.currentItem?.presentationSize else { return }
        (0..<2).forEach { i in
            let playerLayer = AVPlayerLayer(player: self.player)
            playerLayer.videoGravity = .resize
            playerLayer.frame = CGRect(origin: .zero, size: contentSize)
            
            let eyeViewLayer = CALayer()
            eyeViewLayer.backgroundColor = NSColor.darkGray.cgColor
            
            let targetEyeView = i == 0 ? leftView : rightView
            projectionMethod?.eyeLayerHandler(eyeViewLayer, i, contentSize, playerLayer, targetEyeView)
            
            eyeViewLayer.addSublayer(playerLayer)
            targetEyeView.contents = eyeViewLayer
        }
        
        
    }
    
    func toggleFullscreen() {
        if self.isInFullScreenMode {
            exitFullScreenMode(options: [:])
            NSCursor.unhide()
        } else {
            guard let screen = SPSVR.screen else { return }
            enterFullScreenMode(
                screen,
                withOptions: [.fullScreenModeAllScreens: false]
            )
            NSCursor.hide()
        }
    }
    
    func advancePlaybackBySeconds(
        seconds: Int
    ) {
        guard let player = player else { return }
        player.seek(
            to: CMTimeAdd(
                player.currentTime(),
                CMTime(
                    value: Int64(seconds),
                    timescale: 1
                )
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 53:
            if isInFullScreenMode {
                toggleFullscreen()
            } else {
                window?.close()
            }
        case 36:
            toggleFullscreen()
        case 49:
            guard let player = player else { return }
            if player.rate != 0 && player.error == nil {
                player.pause()
            } else {
                player.play()
            }
        case 124:
            advancePlaybackBySeconds(seconds: 15)
        case 123:
            advancePlaybackBySeconds(seconds: -15)
        case 34:
            leftView.showsStatistics = !leftView.showsStatistics
            rightView.showsStatistics = leftView.showsStatistics
        case 15:
            leftView.yaw = 0
            leftView.pitch = 0
            leftView.roll = 0
            syncRightCameraFromLeft()
        default:
            print("Key Down: \(event.keyCode)")
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        let speed = 0.3
        leftView.yaw += event.deltaX * speed
        leftView.pitch += event.deltaY * speed
        syncRightCameraFromLeft()
    }
    
    @objc
    private func psvrDataReceivedNotification(note: NSNotification) {
        guard let data: SPSVRData = note.userInfo?[SPSVRData.psvrDataReceivedNotificationDataKey] as? SPSVRData else {
            return
        }
        
        let accelerationCoef = 0.00003125
        leftView.yaw += Double(data.yawAcceleration) * accelerationCoef
        leftView.pitch += Double(data.pitchAcceleration) * accelerationCoef
//        leftView.roll += Double(data.rollAcceleration) * accelerationCoef
        syncRightCameraFromLeft()
    }
    
    func syncRightCameraFromLeft() {
        rightView.yaw = leftView.yaw
        rightView.pitch = leftView.pitch
        rightView.roll = leftView.roll
    }
}

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

