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
    
    
    static func filterByArray(items: [NSMutableDictionary], var filter: String, column: String) -> [NSMutableDictionary] {
        
        filter = filter.stringByReplacingOccurrencesOfString(", ", withString: ",")
        
        var filterSplit = [String]()
        filterSplit = filter.characters.split{$0 == ","}.map(String.init)
        
        return items.filter({
            filterSplit.contains(String($0[column]!))
        })
        
    }
    
    
    static func saveDefaultsDictionary(key: String, dictionary: [NSMutableDictionary]) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let rowsAsData = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        defaults.setObject(rowsAsData, forKey: key)
        defaults.synchronize()

    }
    
    
    static func loadDefaultsDictionary(key: String) -> [NSMutableDictionary] {
        
        let defaultsData = NSUserDefaults.standardUserDefaults().dataForKey(key)
        var returnDictionary: [NSMutableDictionary] = [["": ""]]
        
        if (defaultsData != nil) {
            let storedDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(defaultsData!)
            returnDictionary = storedDictionary!.mutableCopy() as! [NSMutableDictionary]
        }
        
        return returnDictionary
    
    }
    
    
}