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
    
    
    static func parse(importFileURL: NSURL) -> [NSMutableDictionary] {
        
        // TODO: remember to delete the temp folder at the end
        let tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
        
        let notAvailable = "" // formerly "--"
        var rows: [NSMutableDictionary] = [["": ""]]
        
        // unzip the shit out of it!
        do {
            let archive: ZZArchive = try ZZArchive(URL: importFileURL)
            let fileManager = NSFileManager.defaultManager()
            
            for index in 1...archive.entries.count {
                // ZipZap Doc https://github.com/pixelglow/zipzap
                let entry = archive.entries[index-1]
                let entryURL = tmpDirURL.URLByAppendingPathComponent(entry.fileName)
                try! fileManager.createDirectoryAtURL(entryURL.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
                try! entry.newData().writeToURL(entryURL, atomically: false)
            }
            
            // then parsing
            // https://github.com/drmohundro/SWXMLHash
            
            // xl/_rels/workbook.xml.rels
            var xmlURL = tmpDirURL.URLByAppendingPathComponent("xl/_rels/workbook.xml.rels")
            var xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
            let workbookRelsXML = SWXMLHash.parse(xmlToParse as String)
            var workbookRels = [String: String]()
            for xmlRow in workbookRelsXML["Relationships"]["Relationship"] {
                workbookRels[(xmlRow.element?.attributes["Id"])!] = xmlRow.element?.attributes["Target"]
            }
            
            // xl/workbook.xml leading to sheet name: url nsdictionary
            let cardTypes =  ["Myths", "Schemes", "Events", "Attachments"]  // TODO: redo dynamically from an editable UI element
            xmlURL = tmpDirURL.URLByAppendingPathComponent("xl/workbook.xml")
            xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
            let workbookXML = SWXMLHash.parse(xmlToParse as String)
            var sheets = [String: String]()
            for xmlRow in workbookXML["workbook"]["sheets"]["sheet"] {
                let sheetAttrName = xmlRow.element?.attributes["name"]
                if cardTypes.contains(sheetAttrName!) {
                    let rid = xmlRow.element?.attributes["r:id"]
                    sheets[sheetAttrName!] = workbookRels[rid!]
                }
            }
            
            // xl/sharedStrings.xml
            xmlURL = tmpDirURL.URLByAppendingPathComponent("xl/sharedStrings.xml")
            xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
            let sharedStringsXML = SWXMLHash.parse(xmlToParse as String)
            var sharedStrings = [String]()
            for xmlRow in sharedStringsXML["sst"]["si"] {
                sharedStrings.append((xmlRow["t"].element?.text)!)
            }
            
            // get all keys to create a NSDictionary from them later
            var allColsSet = Set<String>()
            for (_, value) in sheets {
                xmlURL = tmpDirURL.URLByAppendingPathComponent("xl/" + value)
                xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
                let colXML = SWXMLHash.parse(xmlToParse as String)
                let rows = colXML["worksheet"]["sheetData"]["row"]
                var cols = Set<String>()
                let row = rows[0]
                for col in row["c"] {
                    if col["v"].element?.text != nil {
                        let index = Int((col["v"].element?.text)!)
                        cols.insert(sharedStrings[index!])
                    }
                }
                allColsSet = allColsSet.union(cols)
            }
            let keys = Array(allColsSet)
            let keyset = NSDictionary.sharedKeySetForKeys(keys)
            
            // the full stack of cards
            rows.removeAll() // remove all rows to overwrite the data stored in defaults
            for (_, value) in sheets {
                xmlURL = tmpDirURL.URLByAppendingPathComponent("xl/" + value)
                xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
                let xml = SWXMLHash.parse(xmlToParse as String)
                let firstRow = xml["worksheet"]["sheetData"]["row"][0]
                var localKeys = [String]()
                for col in firstRow["c"] {
                    if col["v"].element?.text != nil {
                        let index = Int((col["v"].element?.text)!)
                        localKeys.append(sharedStrings[index!])
                    }
                }
                //localKeys = localKeys.sort({ $0 < $1 })
                
                var xmlRowNum = 0
                for xmlRow in xml["worksheet"]["sheetData"]["row"] {
                    xmlRowNum += 1
                    let cell = NSMutableDictionary(sharedKeySet: keyset)
                    var empty = true
                    for key in keys {
                        // look into local keys for index by value
                        let localKeyIndex = localKeys.indexOf(key)
                        if localKeyIndex == nil {
                            cell.setObject(notAvailable, forKey: key)
                        } else {
                            let excelCol = XLSX.toExcelCol(localKeyIndex!) + String(xmlRowNum)
                            do {
                                let xmlCell = try xmlRow["c"].withAttr("r", excelCol)
                                if xmlCell.element?.attributes["t"] == "s" {
                                    // fetch the referenced s
                                    let index = Int((xmlCell["v"].element?.text)!)
                                    cell.setObject(sharedStrings[index!], forKey: key)
                                    empty = false
                                } else if xmlCell.element?.attributes["t"] == "str" {
                                    // here we just use the value
                                    cell.setObject((xmlCell["v"].element?.text)!, forKey: key)
                                    empty = false
                                } else {
                                    cell.setObject(notAvailable, forKey: key)
                                }
                            } catch {
                                cell.setObject(notAvailable, forKey: key)
                            }
                        }
                    }
                    if !empty {
                        rows.append(cell)
                    }
                }
            }
            
        } catch {
            print("Failed to unpack the XLSX.")
        }
        
        return rows
        
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