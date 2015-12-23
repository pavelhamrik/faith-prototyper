//
//  AttributeString.swift
//  Faith Prototyper
//
//  Created by Gex on 23/12/15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Foundation
import Cocoa


class AttributedString {
  
  func AttributeCompose (inputString: String) -> NSAttributedString {
      // changes font of the provided string to FaithIcons, returns NSAttributedString object
    
    var attributes: [String: AnyObject] = [NSFontAttributeName: NSNull()]
    attributes[NSFontAttributeName] = NSFont(name: "FaithIcons", size: 12.0)
      // Don't forget to adjust size
    
    return NSAttributedString(string: "\(inputString)", attributes: attributes)
    }
    
}