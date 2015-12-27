//
//  XLSX.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class XLSX2 {
    
    // TODO: remember to delete the temp folder at the end
    static let tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    
    static var sharedStrings = [String]()
    
    static var sharedKeys = [String]()
    
    
    static func parse(importFileURL: NSURL) -> [NSMutableDictionary] {
        
        //let notAvailable = "" // formerly "--"
        let rows = [NSMutableDictionary]()
        
        XLSX2.loadSharedStrings()
        
        if ZipZapHelpers.unzip(importFileURL, tmpDirURL: tmpDirURL) {
            
            let sheets = XLSX2.sheetNameToPath()

            // remove all irrelevant sheets
            // TODO: Types in Preferences
            let supportedCardTypes = ["Myths", "Schemes", "Events", "Attachments"]
            for (key, _) in sheets {
                if !supportedCardTypes.contains(key as! String) {
                    sheets.removeObjectForKey(key)
                }
            }
            
            for (_, value) in sheets {
                let colsWithIndexes = XLSX2.getColsWithIndexes(String(value))
                print(colsWithIndexes)
            }
            
            print(sharedKeys)
            
        }
        
        return rows
        
    }
    
    
    // loads the shared strings from their XML file into the sharedStrings static variable
    
    static func loadSharedStrings() -> Int {
        
        let xmlToParse = try! NSString(contentsOfURL: tmpDirURL.URLByAppendingPathComponent("xl/sharedStrings.xml"), encoding: NSUTF8StringEncoding)
        let xmlParsed = SWXMLHash.parse(xmlToParse as String)
        
        for xmlRow in xmlParsed["sst"]["si"] {
            sharedStrings.append((xmlRow["t"].element?.text)!)
        }
    
        return sharedStrings.count
    
    }
    
    
    // returns the first row of a sheet (to be used e.g. as keys)
    
    static func getColsWithIndexes(path: String) -> NSMutableDictionary {
        
        let results = NSMutableDictionary()
        
        let rows = XLSX2.parseBranchInFile(["worksheet", "sheetData", "row"], path: "xl/" + path)
        
        for (index, cell) in (rows["0"] as! XMLElement).children.enumerate() {
            let sharedString = getElementValue(cell)
            results.setObject(sharedString, forKey: String(index))
            
            if !sharedKeys.contains(getElementValue(cell)) {
                sharedKeys.append(getElementValue(cell))
            }
        }
    
        return results
        
    }
    
    
    // returns a dictionary of a sheet name and its path in the XLSX archive
    
    static func sheetNameToPath() -> NSMutableDictionary {
        
        let results = NSMutableDictionary()
        
        let sheetIDs = XLSX2.parseBranchInFile(["Relationships", "Relationship"], keyAttr: "Id", valueAttr: "Target", path: "xl/_rels/workbook.xml.rels", returnType: "attributes")
        let sheetNames = XLSX2.parseBranchInFile(["workbook", "sheets", "sheet"], keyAttr: "r:id", valueAttr: "name", path: "xl/workbook.xml", returnType: "attributes")

        for (key, value) in sheetIDs {
            if sheetNames[String(key)] != nil {
                results.setObject(value, forKey: String(sheetNames[String(key)]!))
            }
        }
        
        return results
        
    }
    
    
    // helper to translate an element into its value
    
    static func getElementValue(element: XMLElement) -> String {
        
        if element.attributes.keys.contains("t") {
            if element.attributes["t"]! == "s" {
                return sharedStrings[Int(element.children.first!.text!)!]
            }
        }
        else if element.children.first != nil {
            return element.children.first!.text!
        }
    
        return ""
        
    }

    
    // helper to get selected attributes of a target branch of a xml tree
    
    static func parseBranchInFile(branch: [String], path: String) -> NSMutableDictionary {
        return XLSX2.parseBranchInFile(branch, keyAttr: "", valueAttr: "", path: path, returnType: "elements")
    }
    
    static func parseBranchInFile(branch: [String], keyAttr: String, valueAttr: String, path: String) -> NSMutableDictionary {
        return XLSX2.parseBranchInFile(branch, keyAttr: keyAttr, valueAttr: valueAttr, path: path, returnType: "attributes")
    }
    
    static func parseBranchInFile(branch: [String], keyAttr: String, valueAttr: String, path: String, returnType: String) -> NSMutableDictionary {
        
        let results = NSMutableDictionary()
        
        let xmlToParse = try! NSString(contentsOfURL: tmpDirURL.URLByAppendingPathComponent(path), encoding: NSUTF8StringEncoding)
        let xmlParsed = SWXMLHash.parse(xmlToParse as String)
        
        var xmlParsedTarget = xmlParsed
        
        switch branch.count {
            
        case 1:
            xmlParsedTarget = xmlParsed[branch[0]]
            
        case 2:
            xmlParsedTarget = xmlParsed[branch[0]][branch[1]]
            
        case 3:
            xmlParsedTarget = xmlParsed[branch[0]][branch[1]][branch[2]]
            
        case 4:
            xmlParsedTarget = xmlParsed[branch[0]][branch[1]][branch[2]][branch[3]]
            
        case 5:
            xmlParsedTarget = xmlParsed[branch[0]][branch[1]][branch[2]][branch[3]][branch[4]]
            
        default:
            print ("parseBranchInFile: Requested XML branch nesting too deep.")
        
        }
        
        switch returnType {
            
        case "attributes":
            for row in xmlParsedTarget {
                results.setObject((row.element?.attributes[valueAttr])!, forKey: (row.element?.attributes[keyAttr])!)
            }
            
        case "elements":
            var i = 0
            for row in xmlParsedTarget {
                results.setObject((row.element)!, forKey: String(i))
                i += 1
            }
            
        default:
            break
            
        }
        
        return results
        
    }
    
    
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
