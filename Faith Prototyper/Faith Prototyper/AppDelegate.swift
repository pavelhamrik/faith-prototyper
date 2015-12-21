//
//  AppDelegate.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {

    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    var preferencesController: NSWindowController?
    @IBAction func showPreferences(sender : AnyObject) {
        print("showPreferences")
        if (preferencesController == nil) {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            preferencesController = storyboard.instantiateInitialController() as? NSWindowController
            print("preferencesController == nil")
        }
        print(preferencesController)
        if (preferencesController != nil) {
            preferencesController!.showWindow(sender)
            print("preferencesController != nil")
        }
    }
    
}

