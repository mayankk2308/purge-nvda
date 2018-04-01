//
//  ScriptManager.swift
//  Purge NVIDIA
//
//  Created by Mayank Kumar on 2/5/18.
//  Copyright © 2018 Mayank Kumar. All rights reserved.
//

import Foundation

struct Scripts {
    static let enableAMDeGPUs = ""
    static let purgedGPU = ""
    static let restoreDefault = ""
}


class ScriptManager {
    
    static func execute(withScript script: String, terminationHandler: ((Int) -> Void)?) {
        DispatchQueue(label: "script").async {
            guard let appleScript = NSAppleScript(source: script) else {
                if terminationHandler != nil {
                    terminationHandler!(-1)
                }
                return
            }
            var scriptError: NSDictionary?
            appleScript.executeAndReturnError(&scriptError)
            if let error = scriptError {
                let errorCode = error["NSAppleScriptErrorNumber"] as! Int
                if terminationHandler != nil {
                    terminationHandler!(errorCode)
                }
            } else {
                if terminationHandler != nil {
                    terminationHandler!(0)
                }
            }
        }
    }
}
