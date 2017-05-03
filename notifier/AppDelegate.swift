//
//  AppDelegate.swift
//  notifier
//
//  Created by walkingmask on 2017/05/03.
//  Copyright © 2017 rudt. All rights reserved.
//

import Cocoa
import ScriptingBridge
import ObjectiveC.runtime

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let NotificationCenterUIBundleID = "com.apple.notificationcenterui"

    func usage(){
        print("This is help message")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let userNotification = aNotification.userInfo?[NSApplicationLaunchUserNotificationKey]
        if (userNotification != nil) {
            self.activatedNotification(userNotification: userNotification as! NSUserNotification)
            return
        }
        
        if ((ProcessInfo().arguments.index(of: "--help")) != nil) {
            self.usage()
            exit(0)
        }
        
        let runnningProcs = NSWorkspace.shared().runningApplications.filter { $0.bundleIdentifier == NotificationCenterUIBundleID }
        if (runnningProcs.count == 0) {
            NSLog("[!] Unable to post a notification for the current user (%@), as it has no running NotificationCenter instance.", NSUserName())
            exit(1)
        }
        
        let ud = UserDefaults.standard;
        
        let subtitle = ud.string(forKey: "subtitle")
        let message = ud.string(forKey: "message")
        let sound = ud.string(forKey: "sound")
        
        if (message == nil) {
            self.usage()
            exit(1)
        }
        
        var options = Dictionary<String, String>()
        if (ud.string(forKey: "activate") != nil) {
            options["bundleID"] = ud.string(forKey: "activate")!
        }
        if (ud.string(forKey: "group") != nil) {
            options["groupID"] = ud.string(forKey: "group")!
        }
        if (ud.string(forKey: "execute") != nil) {
            options["command"] = ud.string(forKey: "execute")!
        }
        if (ud.string(forKey: "appIcon") != nil) {
            options["appIcon"] = ud.string(forKey: "appIcon")!
        }
        if (ud.string(forKey: "contentImg") != nil) {
            options["contentImage"] = ud.string(forKey: "contentImage")!
        }
        if (ud.string(forKey: "closeLabel") != nil) {
            options["closeLabel"] = ud.string(forKey: "closeLabel")!
        }
        if (ud.string(forKey: "dropdownLabel") != nil) {
            options["dropdownLabel"] = ud.string(forKey: "dropdownLabel")!
        }
        if (ud.string(forKey: "actions") != nil) {
            options["actions"] = ud.string(forKey: "actions")!
        }
        
        if (ProcessInfo.processInfo.arguments.contains("-reply")) {
            options["reply"] = "reply"
            if (ud.string(forKey: "reply") != nil) {
                options["reply"] = ud.string(forKey: "reply")!
            }
        }
        
        options["output"] = "outputEvent"
        options["uuid"] = String.init(format: "%ld", self.hash)
        let timeout = ud.string(forKey: "timeout")
        options["timeout"] = timeout != nil ? timeout! : "0"
        
        if (options["reply"] != nil || timeout != nil || ud.string(forKey: "actions") != nil) {
            options["waitForResponse"] = "wait"
        }
        
        if (ud.string(forKey: "open") != nil) {
            let encodedURL = ud.string(forKey: "open")!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let url = URL(string: encodedURL)
            let fragment = url!.fragment
            if (fragment != nil) {
                options["open"] = self.decodeFragmentInURL(encodedURL: encodedURL, fragment: fragment!)
            } else {
                options["open"] = encodedURL
            }
        }
        
        options["uuid"] = String.init(format: "%ld", self.hash)
        
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func decodeFragmentInURL(encodedURL: String, fragment: String) -> String {
        let beforeStr = "%23" + fragment
        let afterStr = "#" + fragment
        let decodedURL = encodedURL.replacingOccurrences(of: beforeStr, with: afterStr)
        return decodedURL
    }
    
    func activatedNotification(userNotification: NSUserNotification) {
        NSUserNotificationCenter.default.removeDeliveredNotification(userNotification)
        
        // let groupID = userNotification.userInfo?["groupID"]
        let bundleID = userNotification.userInfo?["bundleID"]
        let open = userNotification.userInfo?["open"]
        
        if (bundleID != nil) {
            self.activateAppWithBundleID(bundleID: bundleID as! String)
        }
        if (open != nil) {
            NSWorkspace.shared().open(URL(string: open as! String)!)
        }
    }
    
    func activateAppWithBundleID(bundleID: String) {
        let app = SBApplication(bundleIdentifier: bundleID)
        if (app != nil) {
            app!.activate()
            return
        }
        NSLog("Unable to find an application with the specified bundle indentifier.")
    }

}

