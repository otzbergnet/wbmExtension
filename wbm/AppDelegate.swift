//
//  AppDelegate.swift
//  wbm
//
//  Created by Claus Wolf on 14.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool{
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager
            .shared()
            .setEventHandler(
                self,
                andSelector: #selector(handleURL(event:reply:)),
                forEventClass: AEEventClass(kInternetEventClass),
                andEventID: AEEventID(kAEGetURL)
            )

    }

    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        if let path = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue?.removingPercentEncoding {
            NSLog("wbm_log: \(path)")
            let myTabBar = NSApplication.shared.mainWindow?.windowController?.contentViewController as! NSTabViewController
            myTabBar.tabView.selectTabViewItem(at: 1)
        }
    }
    
}
