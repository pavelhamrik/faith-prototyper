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
    
}