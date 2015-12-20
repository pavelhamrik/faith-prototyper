//
//  XLSX.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

//
//  ShapeDrawer.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class XLSX {
    
    // helper function translating col number to excel column index
    static func toExcelCol(colNum: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        if colNum < 26 {
            return letters[colNum]
        }
        else {
            return toExcelCol(colNum / 26 - 1) + toExcelCol(colNum % 26)
        }
    }

}