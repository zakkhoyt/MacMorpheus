//
//  VideoPlayerView.swift
//  MacMorpheus
//
//  Created by Zakk Hoyt on 7/30/23.
//  Copyright © 2023 emoRaivis. All rights reserved.
//

import AppKit
import Foundation

extension NSNotification.Name {
    static let psvrDataReceivedNotification = Notification.Name("PSVRDataReceivedNotification")
    static let psvrDataReceivedNotificationDataKey = Notification.Name("PSVRDataReceivedNotificationDataKey")
}


class SPSVR: NSObject {
    static let shared = SPSVR()
    static var screen: NSScreen? {
        .main
    }
}


class SPSVRData: NSObject {
    
    var yawAcceleration: Int16 {
        self.readInt16(offset: 20) + self.readInt16(offset: 36)
    }
    
    var pitchAcceleration: Int16 {
        self.readInt16(offset: 22) + self.readInt16(offset: 38)
    }
    
    var rollAcceleration: Int16 {
        self.readInt16(offset: 24) + self.readInt16(offset: 40)
    }

    private var rawData: Data
    
    init(data: Data) {
        self.rawData = data
        super.init()
    }
    
    private func readInt16(offset: Int) -> Int16 {
        var output: Int16 = 0
        (rawData as NSData).getBytes(
            &output,
            range: NSRange(
                location: offset,
                length: MemoryLayout<Int16>.size
            )
        )
        return output
    }
}
