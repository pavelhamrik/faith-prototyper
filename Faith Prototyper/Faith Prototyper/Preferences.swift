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
        //self.groups.setDelegate(self)
        self.statuses.setDelegate(self)
        
        let defaultTypes = Helpers.loadDefaults("prefsExportTypes")
        if (!(defaultTypes ?? "").isEmpty) {
            types.stringValue = defaultTypes
        }

        let defaultStatuses = Helpers.loadDefaults("prefsExportStatuses")
        if (!(defaultStatuses ?? "").isEmpty) {
            statuses.stringValue = defaultStatuses
        }

        // TODO: useImages
        
    }
    
    override func controlTextDidChange(notification: NSNotification?) {
        
        if notification?.object as? NSComboBox == self.groups {
            Helpers.saveDefaults("prefsExportGroups", value: self.groups.stringValue)
        }
        
    }
    

    
    
    
}
