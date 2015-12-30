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
    
    static var rows = [[String: String]]()
    

    static func parse(importFileURL: NSURL) -> [[String: String]] {
        
        // initialize the strings shared across all sheets
        XLSX2.loadSharedStrings()
        
        // empty rows
        self.rows.removeAll()
        
        if ZipZapHelpers.unzip(importFileURL, tmpDirURL: tmpDirURL) {
            
            var sheetNames = XLSX2.sheetNameToPath()
            
            var colsWithIndexes = [String: [String: String]]()

            // remove all irrelevant sheets
            // TODO: Types in Preferences
            let supportedCardTypes = ["Myths", "Schemes", "Events", "Attachments"]
            for (name, path) in sheetNames {
                if !supportedCardTypes.contains(name) {
                    sheetNames.removeValueForKey(name)
                }
                else {
                    // needs to run in a separate loop from the main one to fill the sharedKeys array properly
                    colsWithIndexes.updateValue(XLSX2.getColsWithIndexes(String(path)), forKey: String(name))
                }
            }
            
            // simple sorting of shared keys for more legible output in tableView
            //sharedKeys.sortInPlace({ $0 < $1 })

            // info
            for (key, value) in colsWithIndexes {
                print("colsWithIndexes.count – " + String(key) + ": " + String(value.count))
            }
            print(sharedKeys)
            
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
    
    static func parseSheet(path: String, type: String, colsWithIndexes: [String: [String: String]]) {
        
        let xmlRows = self.parseIndexersBranchInFile(["worksheet", "sheetData", "row"], path: "xl/" + path)
        
        for (rowIndex, xmlRow) in xmlRows.enumerate() {
            
            if rowIndex == 0 {
                continue
            }
            
            var row = [String: String]()
            
            //let xmlRow = xmlRows[String(rowindex)]!.children
            //let xmlRow = xmlRows.withAttr("r", rowindex)
            var empty = true
            
            for (_, sharedKey) in self.sharedKeys.enumerate() {
                
                if colsWithIndexes[type]![sharedKey] != nil {
                    
                    let index = Int(colsWithIndexes[type]![sharedKey]!)

                    // xlsx col index, e.g. P9
                    do {
                        
                        let coords = String(self.toExcelCol(index!)) + String(rowIndex + 1)
                        let element = try xmlRow["c"].withAttr("r", coords).element
                        
                        let value = getElementValue(element!)
                        if value != "" && value != " " {
                            empty = false
                            row.updateValue(value, forKey: sharedKey)
                        }
                        else {
                            row.updateValue("", forKey: sharedKey)
                        }
                        
                    }
                    catch {
                        row.updateValue("", forKey: sharedKey)
                    }
                    
                }
                else {
                    row.updateValue("", forKey: sharedKey)
                }
                
            }

            if !empty {
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
    
    static func getColsWithIndexes(path: String) -> [String: String] {
        
        var results = [String: String]()
        
        let rows = XLSX2.parseElementsBranchInFile(["worksheet", "sheetData", "row"], path: "xl/" + path)
        
        for (index, cell) in rows["0"]!.children.enumerate() {
            
            let sharedString = getElementValue(cell)
            if sharedString != "" && sharedString != " " {
                results.updateValue(String(index), forKey: sharedString)
            }
            
            if !sharedKeys.contains(getElementValue(cell)) && sharedString != "" && sharedString != " " {
                sharedKeys.append(getElementValue(cell))
            }
            
        }
    
        return results
        
    }
    
    
    // returns a dictionary of a sheet name and its path in the XLSX archive
    
    static func sheetNameToPath() -> [String: String] {
        
        var results = [String: String]()
        
        let sheetIDs = XLSX2.parseAttributesBranchInFile(["Relationships", "Relationship"], keyAttr: "Id", valueAttr: "Target", path: "xl/_rels/workbook.xml.rels")
        let sheetNames = XLSX2.parseAttributesBranchInFile(["workbook", "sheets", "sheet"], keyAttr: "r:id", valueAttr: "name", path: "xl/workbook.xml")

        for (key, value) in sheetIDs {
            if sheetNames[String(key)] != nil {
                results.updateValue(String(value), forKey: String(sheetNames[String(key)]!))
            }
        }
        
        return results
        
    }
    
    
    // helper to translate an element into its value
    
    static func getElementValue(element: XMLElement) -> String {
        
        var output = ""
        
        if element.attributes.keys.contains("t") {
            if element.attributes["t"]! == "s" {
                output = self.sharedStrings[Int(element.children.first!.text!)!]
            }
        }
        else if element.attributes.keys.contains("t") {
            if element.attributes["t"]! == "str" {
                output = element.children.first!.text!
            }
        }
        else if element.children.first != nil {
            output = element.children.first!.text!
        }
        
        // handling numeric values
        if Float(output) != nil {
            if Float(output)! == round(Float(output)!) {
                output = String(Int(Float(output)!))
            }
            else {
                output = String(Float(output)!)
            }
        }
    
        return output
        
    }

    
    // helper to get selected attributes of a target branch of a xml tree
    
    static func parseAttributesBranchInFile(branch: [String], keyAttr: String, valueAttr: String, path: String) -> [String: String] {
        
        var results = [String: String]()
        
        let xmlParsedTarget = parseBranchHelper(branch, path: path)

        for row in xmlParsedTarget {
            results.updateValue((row.element?.attributes[valueAttr])!, forKey: (row.element?.attributes[keyAttr])!)
        }
        
        return results
        
    }
    
    
    // helper to get selected elements of a target branch of a xml tree
    
    static func parseElementsBranchInFile(branch: [String], path: String) -> [String: XMLElement] {
        
        let xmlParsedTarget = parseBranchHelper(branch, path: path)
        
        var results = [String: XMLElement]()
        
        for (index, row) in xmlParsedTarget.enumerate() {
            results.updateValue((row.element)!, forKey: String(index))
        }
        
        return results
        
    }
    
    
    // helper to get selected elements of a target branch of a xml tree
    
    static func parseIndexersBranchInFile(branch: [String], path: String) -> [XMLIndexer] {
        
        let xmlParsedTarget = parseBranchHelper(branch, path: path)
        
        var results = [XMLIndexer]()
        
        for row in xmlParsedTarget {
            results.append(row)
        }
        
        return results
        
    }
    
    
    // helper to address the xml tree branch
    
    static func parseBranchHelper(branch: [String], path: String) -> XMLIndexer {
        
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
        
        return xmlParsedTarget
    
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
