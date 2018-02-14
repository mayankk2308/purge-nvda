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
    
}

extension AppDelegate {
    
    func genericPurge(withArg arg: String) {
        let script = "do shell script \"/usr/local/bin/purge-nvda \(arg)\" with administrator privileges"
        ScriptManager.execute(withScript: script) { error in
            self.showDialog(withStatusCode: error)
        }
    }
    
    func reboot() {
        let script = "tell application \"Finder\" to restart"
        ScriptManager.execute(withScript: script, terminationHandler: nil)
    }
    
}

extension AppDelegate {
    
    func showDialog(withStatusCode statusCode: Int) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Purge NVIDIA"
            switch(statusCode) {
            case -1:
                alert.informativeText = "The underlying binary for the application was not found. Please reinstall the application."
                alert.addButton(withTitle: "OK")
                alert.runModal()
                break
            case 0:
                alert.informativeText = "Changes have been made. Please reboot to apply changes."
                alert.addButton(withTitle: "Restart Now")
                alert.addButton(withTitle: "Restart Later")
                if alert.runModal() == .alertFirstButtonReturn {
                    self.reboot()
                }
                break
            case 1:
                alert.informativeText = "Only an administrator may run this application."
                alert.addButton(withTitle: "OK")
                alert.runModal()
                break
            case 2:
                alert.informativeText = "Please disable system integrity protection to allow more privileged operations."
                alert.addButton(withTitle: "OK")
                alert.runModal()
                break
            case 3:
                alert.informativeText = "This version of macOS is not supported for enabling AMD eGPUs. Suppressing the dGPU does work, but is also not recommended."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            default:
                return
            }
        }
    }
    
}

extension AppDelegate {
    
    @objc func purge(_ sender: Any?) {
        genericPurge(withArg: "")
    }
    
    @objc func suppressOnly(_ sender: Any?) {
        genericPurge(withArg: "suppress-only")
    }
    
    @objc func restore(_ sender: Any?) {
        genericPurge(withArg: "uninstall")
    }
    
    @objc func launchAtLogin(_ sender: Any?) {
        // launch at login
    }
    
}

