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
}



class SPSVR: NSObject {
    static let shared = SPSVR()
    static var screen: NSScreen? {
        .main
    }
    
    override init() {
        
//        IOHIDManagerRef managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeSeizeDevice);
        let managerRef: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
//        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), CFRunLoopMode.defaultMode!.rawValue)
//        IOHIDManagerSetDeviceMatching(managerRef, (__bridge CFMutableDictionaryRef)@{
        IOHIDManagerSetDeviceMatching(
            managerRef, [
                kIOHIDVendorIDKey: 0x054C,
                kIOHIDProductIDKey: 0x09AF
            ] as CFDictionary
        )
//            @kIOHIDVendorIDKey: @(0x054C),
//            @kIOHIDProductIDKey: @(0x09AF)
//        });
//        IOHIDManagerRegisterInputValueCallback(managerRef, PSVR_HID_InputValueCallback, (__bridge void *)(self));
        IOHIDManagerRegisterInputValueCallback(managerRef, { (inContext: UnsafeMutableRawPointer?, inResult: IOReturn, inSender: UnsafeMutableRawPointer?, inValueRef: IOHIDValue) in
            #warning("FIXME: @zakkhoyt - gotta cast the pointee or ")
            guard let psvr = inContext?.load(as: SPSVR.self) else {
                return
            }
            psvr.processHIDValue(hidValue: inValueRef)
        }, nil)
//        IOHIDManagerOpen(managerRef, 0);
            

    }
    func processHIDValue(hidValue: IOHIDValue) {
        
    }
}


class SPSVRData: NSObject {

    static let psvrDataReceivedNotificationDataKey = "PSVRDataReceivedNotificationDataKey"
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
