//
//  NSAttributedString.swift
//  Faith Prototyper
//
//  Created by mixel
//  http://stackoverflow.com/a/32830756
//

import Foundation

extension SequenceType where Generator.Element: NSAttributedString {
    
    func joinWithSeparator(separator: NSAttributedString) -> NSAttributedString {
        
        var isFirst = true
        return self.reduce(NSMutableAttributedString()) {
            (r, e) in
            if isFirst {
                isFirst = false
            }
            else {
                r.appendAttributedString(separator)
            }
            r.appendAttributedString(e)
            return r
        }
        
    }
    
    func joinWithSeparator(separator: String) -> NSAttributedString {
        
        return joinWithSeparator(NSAttributedString(string: separator))
        
    }
    
}
