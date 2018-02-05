//
//  PurgeMenu.swift
//  Purge NVIDIA
//
//  Created by Mayank Kumar on 2/4/18.
//  Copyright © 2018 Mayank Kumar. All rights reserved.
//

import Foundation
import Cocoa

class PurgeMenu {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    func configureStatusItem() {
        if let menuButton = statusItem.button {
            menuButton.image = NSImage(named: NSImage.Name("StatusBarImage"))
        }
    }
    
    func configureMenus() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable AMD eGPUs", action: #selector(AppDelegate.purge(_:)), keyEquivalent: "D"))
        menu.addItem(NSMenuItem(title: "Suppress dGPU", action: #selector(AppDelegate.suppressOnly(_:)), keyEquivalent: "S"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Re-enable dGPU", action: #selector(AppDelegate.restore(_:)), keyEquivalent: "R"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(AppDelegate.showPreferences(_:)), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
}
