//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate {
    
    var tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    var rows: [NSMutableDictionary] = []
    
    var window = NSWindow()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(tmpDirURL)
        
        window = NSApplication.sharedApplication().windows[0] as NSWindow
        window.delegate = self;
        
        // prefill self.rows with previously stored data
        let defaultsData = NSUserDefaults.standardUserDefaults().dataForKey("DefaultCards")
        if (defaultsData != nil) {
            let storedDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(defaultsData!)
            self.rows = storedDictionary!.mutableCopy() as! [NSMutableDictionary]
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    
    // load the xlsx
    // TODO: remember to delete the temp folder at the end
    @IBAction func loadData(sender: AnyObject) {
        let notAvailable = "" // formerly "--"
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["xlsx"]
        openPanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let importFileURL = openPanel.URL
                
                // unzip the shit out of it
                do {
                    let archive: ZZArchive = try ZZArchive(URL: importFileURL!)
                    let fileManager = NSFileManager.defaultManager()
                    
                    for index in 1...archive.entries.count {
                        // ZipZap Doc https://github.com/pixelglow/zipzap
                        let entry = archive.entries[index-1] // CHECK: There was a change — removed downcast after ZZArchive update
                        let entryURL = self.tmpDirURL.URLByAppendingPathComponent(entry.fileName)
                        try! fileManager.createDirectoryAtURL(entryURL.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
                        try! entry.newData().writeToURL(entryURL, atomically: false)
                    }
                    
                    // then parsing
                    // https://github.com/drmohundro/SWXMLHash
                    
                    let cardTypes =  ["Myths", "Schemes", "Events", "Attachments"]  // redo dynamically from an editable UI element
                    
                    // xl/_rels/workbook.xml.rels
                    var xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/_rels/workbook.xml.rels")
                    var xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
                    let workbookRelsXML = SWXMLHash.parse(xmlToParse as String)
                    var workbookRels = [String: String]()
                    for xmlRow in workbookRelsXML["Relationships"]["Relationship"] {
                        workbookRels[(xmlRow.element?.attributes["Id"])!] = xmlRow.element?.attributes["Target"]
                    }
                    
                    // xl/workbook.xml leading to sheet name: url nsdictionary
                    xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/workbook.xml")
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
                    xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/sharedStrings.xml")
                    xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
                    let sharedStringsXML = SWXMLHash.parse(xmlToParse as String)
                    var sharedStrings = [String]()
                    for xmlRow in sharedStringsXML["sst"]["si"] {
                        sharedStrings.append((xmlRow["t"].element?.text)!)
                    }
                    
                    // get all keys to create a NSDictionary from them later
                    var allColsSet = Set<String>()
                    for (_, value) in sheets {
                        xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/" + value)
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
                    //keys = keys.sort({ $0 < $1 })
                    let keyset = NSDictionary.sharedKeySetForKeys(keys)
                    
                    // the full stack of cards
                    self.rows.removeAll() // remove all rows to overwrite the data stored in defaults
                    for (_, value) in sheets {
                        xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/" + value)
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
                                self.rows.append(cell)
                            }
                        }
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshCardTableView", object: nil, userInfo:["rows": self.rows])
                } catch {
                    print("Failed to unpack the XLSX.")
                }
            }
        }
    }
    
    
    // generate the PDF
    
    @IBAction func generatePDF(sender: AnyObject) {
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["pdf"]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        savePanel.nameFieldStringValue = "Faith Prototype - " + dateFormatter.stringFromDate(NSDate())
        
        savePanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let exportedFileURL = savePanel.URL
                
                if (exportedFileURL?.isFileReferenceURL() != nil) {
                    
                    PDFExporter.generate(exportedFileURL!, rows: self.rows)
                    
                }
            }
        }
        
    }
    
}
