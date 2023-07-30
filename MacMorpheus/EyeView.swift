//
//  VideoPlayerView.swift
//  MacMorpheus
//
//  Created by Zakk Hoyt on 7/30/23.
//  Copyright © 2023 emoRaivis. All rights reserved.
//

import Foundation
import SceneKit

//#import <SceneKit/SceneKit.h>
//
//@interface EyeView : SCNView
//
//@property (nonatomic, assign) id contents;
//
//@property (nonatomic, assign) SCNMatrix4 projectionTransform;
//
//@property (nonatomic, assign) float roll;
//@property (nonatomic, assign) float pitch;
//@property (nonatomic, assign) float yaw;
//
//@end


class SEyeView: SCNView {
    var contents: Any? {
        get {
            dome.materials.first?.diffuse.contents
        }
        set {
            dome.materials = [SCNMaterial.material(contents: contents)]
        }
    }
    
    var projectionTransform: SCNMatrix4 {
        get {
            domeNode.transform
        }
        set {
            domeNode.transform = projectionTransform;
        }
        
    }
    
    var roll: Double = 0 {
        didSet {
            applyCameraTransform()
        }
    }
    var pitch: Double = 0 {
        didSet {
            applyCameraTransform()
        }
    }
    
    var yaw: Double = 0 {
        didSet {
            applyCameraTransform()
        }
    }
    
    private let cameraNode: SCNNode
    private let dome: SCNSphere
    private let domeNode: SCNNode
    
    override init(frame frameRect: NSRect) {
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.yFov = 90
        
        self.dome = SCNSphere(radius: 60.0)
        self.dome.segmentCount = 480
        self.domeNode = SCNNode(geometry: dome)

        super.init(frame: frameRect)
        
        self.scene = SCNScene()
        self.scene?.rootNode.addChildNode(cameraNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func applyCameraTransform() {
        cameraNode.transform = {
            var matrix = SCNMatrix4Identity
            matrix = SCNMatrix4Mult(
                matrix,
                SCNMatrix4MakeRotation((roll * .pi) / 180, 0, 0, 1)
            )
            matrix = SCNMatrix4Mult(
                matrix,
                SCNMatrix4MakeRotation((pitch * .pi) / 180, 1, 0, 0)
            )
            matrix = SCNMatrix4Mult(
                matrix,
                SCNMatrix4MakeRotation((yaw * .pi) / 180, 0, 1, 0)
            )
            return matrix
        }()
    }
}

extension SCNMaterial {
    static func material(contents: Any?) -> SCNMaterial {
        let material = SCNMaterial()
        material.cullMode = .front
        material.diffuse.contents = contents
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        return material
    }
}

