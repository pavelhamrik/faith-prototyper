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
    
    static var rows = [NSMutableDictionary]()
    
    
    static func parse(importFileURL: NSURL) -> [NSMutableDictionary] {
        
        // initialize the strings shared across all sheets
        XLSX2.loadSharedStrings()
        
        if ZipZapHelpers.unzip(importFileURL, tmpDirURL: tmpDirURL) {
            
            let sheetNames = XLSX2.sheetNameToPath()
            
            let colsWithIndexes = NSMutableDictionary()

            // remove all irrelevant sheets
            // TODO: Types in Preferences
            let supportedCardTypes = ["Myths", "Schemes", "Events", "Attachments"]
            for (name, path) in sheetNames {
                if !supportedCardTypes.contains(name as! String) {
                    sheetNames.removeObjectForKey(name)
                }
                else {
                    // needs to run in a separate loop from the main one to fill the sharedKeys array properly
                    colsWithIndexes.setObject(XLSX2.getColsWithIndexes(String(path)), forKey: String(name))
                }
            }
            
            // simple sorting of shared keys for more legible output in tableView
            sharedKeys.sortInPlace({ $0 < $1 })

            print("sharedKeys.count: " + String(sharedKeys.count))
            for (key, value) in colsWithIndexes {
                print("colsWithIndexes.count – " + String(key) + ": " + String(value.count))
            }
            print(sharedKeys)
            print(colsWithIndexes)
            
            
            if colsWithIndexes.count > 0 {
                
                // get a sheet and parse it
                for (name, path) in sheetNames {
                    
                    self.parseSheet(String(path), type: String(name), colsWithIndexes: colsWithIndexes)
                    
                }
            
            }
            
        }
        
        return self.rows
        
    }
    
    
    // the sheet parsing itself, after all the prepwork by other functions around
    
    static func parseSheet(path: String, type: String, colsWithIndexes: NSMutableDictionary) {
        
        let xmlRows = self.parseBranchInFile(["worksheet", "sheetData", "row"], path: "xl/" + path)
        
        for (rowindex, _) in xmlRows.enumerate() {
            
            if rowindex == 0 {
                continue
            }
            
            let row = NSMutableDictionary(sharedKeySet: NSDictionary.sharedKeySetForKeys(sharedKeys))
            
            let xmlRow = (xmlRows[String(rowindex)] as! XMLElement).children
            var empty = true
            
            for sharedKey in self.sharedKeys {
                
                if colsWithIndexes[type]![sharedKey]! != nil {
                    let index = colsWithIndexes[type]![sharedKey] as! Int
                    
                    if xmlRow.count > index {
                        let value = getElementValue(xmlRow[index])
                        if value != "" && value != " " {
                            empty = false
                            row.setObject(value, forKey: sharedKey)
                        }
                        else {
                            row.setObject("–  –", forKey: sharedKey)
                        }
                    }
                    else {
                        row.setObject("–x–", forKey: sharedKey)
                    }
                    
                }
                else {
                    row.setObject("n/a", forKey: sharedKey)
                }
                
            }

            if !empty {
                print(row)
                self.rows.append(row)
            }
            
        }
        
    }
    
    
    // loads the shared strings from their XML file into the sharedStrings static variable
    
    static func loadSharedStrings() -> Int {
        
        let xmlToParse = try! NSString(contentsOfURL: tmpDirURL.URLByAppendingPathComponent("xl/sharedStrings.xml"), encoding: NSUTF8StringEncoding)
        let xmlParsed = SWXMLHash.parse(xmlToParse as String)
        
        for xmlRow in xmlParsed["sst"]["si"] {
            self.sharedStrings.append((xmlRow["t"].element?.text)!)
        }
    
        return self.sharedStrings.count
    
    }
    
    
    // returns the first row of a sheet (to be used e.g. as keys)
    
    static func getColsWithIndexes(path: String) -> NSMutableDictionary {
        
        let results = NSMutableDictionary()
        
        let rows = XLSX2.parseBranchInFile(["worksheet", "sheetData", "row"], path: "xl/" + path)
        
        for (index, cell) in (rows["0"] as! XMLElement).children.enumerate() {
            
            let sharedString = getElementValue(cell)
            if sharedString != "" && sharedString != " " {
                results.setObject(index, forKey: sharedString)
            }
            
            if !sharedKeys.contains(getElementValue(cell)) && sharedString != "" && sharedString != " " {
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
                return self.sharedStrings[Int(element.children.first!.text!)!]
            }
        }
        else if element.attributes.keys.contains("t") {
            if element.attributes["t"]! == "str" {
                return element.children.first!.text!
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
            for (index, row) in xmlParsedTarget.enumerate() {
                results.setObject((row.element)!, forKey: String(index))
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
