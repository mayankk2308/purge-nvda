//
//  AppDelegate.swift
//  Purge NVIDIA
//
//  Created by Mayank Kumar on 2/4/18.
//  Copyright © 2018 Mayank Kumar. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let purgeMenu = PurgeMenu()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        purgeMenu.configureStatusItem()
        purgeMenu.configureMenus()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func purge(_ sender: Any?) {
        // call purge-nvda
    }
    
    @objc func suppressOnly(_ sender: Any?) {
        // call purge-nvda suppress-only
    }
    
    @objc func restore(_ sender: Any?) {
        // call purge-nvda uninstall
    }

    @objc func showAbout(_ sender: Any?) {
        // call purge-nvda uninstall
    }
    
    @objc func showPreferences(_ sender: Any?) {
        // call purge-nvda uninstall
    }
    
}

