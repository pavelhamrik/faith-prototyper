//
//  Helpers.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 22.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class Helpers {
    
    
    static func saveDefaults(key: String, value: String) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(NSString(UTF8String: value), forKey: key)
        defaults.synchronize()
        
    }
    
    
    static func loadDefaults(key: String) -> String {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let value = defaults.stringForKey(key)
        
        if (value != nil) {
            return value!
        }

        return ""
        
    }
    
    
    // TODO: Move from NSMutableDictionary to Swift value dictionary
    static func filterByArray(items: [[String: String]], var filter: String, column: String) -> [[String: String]] {
        
        filter = filter.stringByReplacingOccurrencesOfString(", ", withString: ",")
        
        var filterSplit = [String]()
        filterSplit = filter.characters.split{$0 == ","}.map(String.init)
        
        return items.filter({
            filterSplit.contains(String($0[column]!))
        })
        
    }
    
    
    static func saveDefaultsDictionary(key: String, dictionary: [[String: String]]) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let rowsAsData = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        defaults.setObject(rowsAsData, forKey: key)
        defaults.synchronize()

    }
    
    
    static func loadDefaultsDictionary(key: String) -> [[String: String]] {
        
        let defaultsData = NSUserDefaults.standardUserDefaults().dataForKey(key)
        var returnDictionary = [[String: String]]()
        
        if (defaultsData != nil) {
            returnDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(defaultsData!) as! [[String: String]]
        }
        
        return returnDictionary
    
    }
    
    
    static func resetDefaults() {
        
        let defaultsData = NSUserDefaults.standardUserDefaults()
        
        let defaults = [
            "DefaultCards",
            "prefsExportTypes",
            "prefsExportGroups",
            "prefsExportStatuses",
            "prefsExportPrintings",
            "prefsExportFactions",
            "prefsExportCardXSpacing",
            "prefsExportCardYSpacing"
        ]
        
        for item in defaults {
            defaultsData.removeObjectForKey(item)
        }
    
    }
    
    
    static func matchesForRegexInText(regex: String, text: String) -> [[String]] {
        
        var results = [[String]]()
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsText = text as NSString
            let matches = regex.matchesInString(text, options: [], range: NSMakeRange(0, nsText.length))
            
            for match in matches {
                var result = [String]()
                for var index = 0; index <= match.numberOfRanges - 1; index++ {
                    result.append(String(nsText.substringWithRange(match.rangeAtIndex(index))))
                }
                results.append(result)
            }
            
        }
        catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
        }
        
        return results
        
    }
    
    
    static func matchesWithRangesForRegexInAttributedText(regex: String, text: NSAttributedString) -> [[(String, NSRange)]] {
        
        var results = [[(String, NSRange)]]()
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let stringText = text.string
            let nsText = text.string as NSString
            let matches = regex.matchesInString(stringText, options: [], range: NSMakeRange(0, nsText.length))
            
            for match in matches {
                var result = [(String, NSRange)]()
                for var index = 0; index <= match.numberOfRanges - 1; index++ {
                    let element = (String(nsText.substringWithRange(match.rangeAtIndex(index))), match.rangeAtIndex(index))
                    result.append(element)
                }
                results.append(result)
            }
            
        }
        catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
        }
        
        return results
        
    }
    
    
    static func runDialog(question: String, text: String) -> Bool {
        
        let alert: NSAlert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            return true
        }
        
        return false
        
    }
    
    
    static func runAlert(question: String, text: String) -> Bool {
        
        let alert: NSAlert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        
        alert.addButtonWithTitle("OK")
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            return true
        }
        
        return false
        
    }
    
    
}
