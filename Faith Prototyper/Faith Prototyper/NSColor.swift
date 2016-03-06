//
//  NSColor.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 28.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

extension NSColor {
    
    
    // Color convenience init from hex, from https://github.com/higepon/Swift-UIKit-Extensions
    
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
        
    }
    
    
    // Color convenience init from Int components
    // TODO: Check
    
    convenience init(r: Int, g: Int, b: Int, a: Int = 255) {
        
        let red = CGFloat(Double(r) / 255.0)
        let green = CGFloat(Double(g) / 255.0)
        let blue = CGFloat(Double(b) / 255.0)
        let alpha = CGFloat(Double(a) / 255.0)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
        
    }
    
    // Color component conversion
    
    func convertColorComponent(colorComponent: Int) -> CGFloat {
        
        return CGFloat(Double(colorComponent) / 255.0)
        
    }
    
}
