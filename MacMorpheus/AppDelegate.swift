//
//  AppDelegate.swift
//  MacMorpheus
//
//  Created by Zakk Hoyt on 7/30/23.
//  Copyright © 2023 emoRaivis. All rights reserved.
//

import AppKit
import Foundation



final class SAppDelegate: NSObject, NSApplicationDelegate {
    private(set) var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            let unwantedMenus = ["File", "Edit"]
            let removeMenus = {
                unwantedMenus.forEach {
                    guard let menu = NSApp.mainMenu?.item(withTitle: $0) else { return }
                    NSApp.mainMenu?.removeItem(menu)
                }
            }

            NotificationCenter.default.addObserver(
                forName: NSMenu.didAddItemNotification,
                object: nil,
                queue: .main
            ) { _ in
                // Must refresh after every time SwiftUI re adds
                removeMenus()
            }

            removeMenus()
            
            //            window.titleVisibility = .hidden
            //            window.titlebarAppearsTransparent = true
            //            window.isOpaque = false
            //            window.backgroundColor = NSColor.clear
            
            self.window = window
        }
        
        let targetURL: URL?
        
    }
}
