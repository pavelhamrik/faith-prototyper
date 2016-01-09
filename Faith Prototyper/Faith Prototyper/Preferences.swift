//
//  Preferences.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa
import AppKit

class Preferences: NSViewController, NSTextFieldDelegate, NSComboBoxDelegate {
    
    
    @IBOutlet weak var types: NSComboBox!
    
    @IBOutlet weak var groups: NSTextField!
    
    @IBOutlet weak var statuses: NSComboBox!
    
    @IBOutlet weak var printings: NSTextField!
    
    @IBOutlet weak var factions: NSComboBox!
    
    @IBOutlet weak var useImages: NSButton!
    
    @IBOutlet weak var cardXSpacing: NSTextField!
    
    @IBOutlet weak var cardYSpacing: NSTextField!

    // NOTE: all checkboxes are handled via bindings from the storyboard


    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.types.setDelegate(self)
        self.groups.delegate = self
        self.statuses.setDelegate(self)
        self.printings.delegate = self
        self.factions.setDelegate(self)
        
        self.cardXSpacing.delegate = self
        self.cardYSpacing.delegate = self
        
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
        
        let defaultPrintings = Helpers.loadDefaults("prefsExportPrintings")
        if (!(defaultPrintings ?? "").isEmpty) {
            printings.stringValue = defaultPrintings
        }
        
        let defaultFactions = Helpers.loadDefaults("prefsExportFactions")
        if (!(defaultFactions ?? "").isEmpty) {
            factions.stringValue = defaultFactions
        }
        
        let defaultCardXSpacing = Helpers.loadDefaults("prefsExportCardXSpacing")
        if (!(defaultCardXSpacing ?? "").isEmpty) {
            cardXSpacing.stringValue = defaultCardXSpacing
        }
        
        let defaultCardYSpacing = Helpers.loadDefaults("prefsExportCardYSpacing")
        if (!(defaultCardYSpacing ?? "").isEmpty) {
            cardYSpacing.stringValue = defaultCardYSpacing
        }
        
        // TODO: useImages
        
    }
    
    
    override func controlTextDidChange(notification: NSNotification?) {
        
        self.processFieldChange(notification!)
        
    }
    
    
    override func controlTextDidEndEditing(notification: NSNotification?) {
        
        self.processFieldChange(notification!)
        
    }
    
    
    @IBAction func restoreDefaults(sender: AnyObject) {
        
        Helpers.resetDefaults()
        
        NSNotificationCenter.defaultCenter().postNotificationName("refreshCardTableView", object: nil, userInfo:["rows": [["And nothing!": "Load some cards..."]]])
        
        Helpers.runAlert("Defaults Restored", text: "Don't be surprised when you can't find anything.")
        
    }

    
    
    func processFieldChange(notification: NSNotification) {
    
        if notification.object as? NSComboBox == self.types {
            Helpers.saveDefaults("prefsExportTypes", value: self.types.stringValue)
        }
        
        if notification.object as? NSTextField == self.groups {
            Helpers.saveDefaults("prefsExportGroups", value: self.groups.stringValue)
        }
        
        if notification.object as? NSComboBox == self.statuses {
            Helpers.saveDefaults("prefsExportStatuses", value: self.statuses.stringValue)
        }
        
        if notification.object as? NSTextField == self.printings {
            Helpers.saveDefaults("prefsExportPrintings", value: self.printings.stringValue)
        }
        
        if notification.object as? NSComboBox == self.factions {
            Helpers.saveDefaults("prefsExportFactions", value: self.factions.stringValue)
        }
        
        if notification.object as? NSTextField == self.cardXSpacing {
            Helpers.saveDefaults("prefsExportCardXSpacing", value: self.cardXSpacing.stringValue)
        }
        
        if notification.object as? NSTextField == self.cardYSpacing {
            Helpers.saveDefaults("prefsExportCardYSpacing", value: self.cardYSpacing.stringValue)
        }
    
    }


}
