//
//  Preferences.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class Preferences: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    
    @IBOutlet weak var types: NSComboBox!
    
    @IBOutlet weak var groups: NSTextField!
    
    @IBOutlet weak var statuses: NSComboBox!
    
    @IBOutlet weak var useImages: NSButton!


    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.types.setDelegate(self)
        self.groups.delegate = self
        self.statuses.setDelegate(self)
        
        let defaultTypes = Helpers.loadDefaults("prefsExportTypes")
        if (!(defaultTypes ?? "").isEmpty) {
            types.stringValue = defaultTypes
        }
        
        let defaultGroups = Helpers.loadDefaults("prefsExportGroups")
        if (!(defaultGroups ?? "").isEmpty) {
            groups.stringValue = defaultGroups
        }
        
        let defaultStatuses = Helpers.loadDefaults("prefsExportStatuses")
        if (!(defaultStatuses ?? "").isEmpty) {
            statuses.stringValue = defaultStatuses
        }
        
        // TODO: useImages
        
    }
    
    override func controlTextDidChange(notification: NSNotification?) {
        
        if notification?.object as? NSComboBox == self.types {
            Helpers.saveDefaults("prefsExportTypes", value: self.types.stringValue)
        }
        
        if notification?.object as? NSTextField == self.groups {
            Helpers.saveDefaults("prefsExportGroups", value: self.groups.stringValue)
        }
        
        if notification?.object as? NSComboBox == self.statuses {
            Helpers.saveDefaults("prefsExportStatuses", value: self.statuses.stringValue)
        }
        
    }

}
