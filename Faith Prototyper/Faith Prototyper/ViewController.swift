//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

protocol cardTableViewProtocol {
    func updateCardTableView(sender: AnyObject, value: AnyObject)
    var rows: [NSMutableDictionary]{get set}
}

class ViewController: NSViewController {
    
    var delegate: CardTable?
    
    var tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    var rows: [NSMutableDictionary] = [
        ["Name": "Ayyaa!"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(tmpDirURL)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList:", name:"refreshCardTableView", object: nil)
    }
       
    func refreshList(notification: NSNotification){
        delegate?.updateCardTableView(self, value: rows)
    }
    
    @IBAction func printVar(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("refreshCardTableView", object: nil)
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    // load the xlsx
    
    @IBAction func loadData(sender : AnyObject) {
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
                    let archive: ZZArchive = try ZZArchive(URL: importFileURL)
                    let fileManager = NSFileManager.defaultManager()
                    
                    for index in 1...archive.entries.count {
                        // ZipZap Doc https://github.com/pixelglow/zipzap
                        let entry = archive.entries[index-1] as! ZZArchiveEntry
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
                    print(sheets)

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
                    let keyset = NSDictionary.sharedKeySetForKeys(keys)
                    
                    //print(keys)
                    
                    // the full stack of cards
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
                        print(value)
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
                                    let excelCol = self.toExcelCol(localKeyIndex!) + String(xmlRowNum)
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
                    //self.cardTableView.reloadData()
                } catch {
                    print("Failed to unpack the XLSX.")
                }
            }
        }
    }
    
    
    @IBAction func generatePDF(sender: AnyObject) {
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let exportedFileURL = savePanel.URL
                
                if (exportedFileURL?.isFileReferenceURL() != nil) {
                    
                    var pageSize = CGRect(x: 0.0, y: 0.0, width: 612, height: 792)
                    
                    let context = CGPDFContextCreateWithURL(exportedFileURL, &pageSize, nil)

                    
                    CGPDFContextBeginPage(context, nil)
                    
                    // http://www.techotopia.com/index.php/Drawing_iOS_8_2D_Graphics_in_Swift_with_Core_Graphics
                    // Graphic Contexts Doc https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html
                    // Processing Images Doc https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html
                    // Learn Quartz http://cocoadevcentral.com/d/intro_to_quartz/
                    
                    CGContextSetRGBFillColor (context, 1, 0, 0, 1);
                    CGContextFillRect (context, CGRectMake (0, 0, 200, 100 ));
                    CGContextSetRGBFillColor (context, 0, 0, 1, 0.5);
                    CGContextFillRect (context, CGRectMake (0, 0, 100, 200));
                    
                    
                    
                    CGPDFContextEndPage(context)
                    CGPDFContextClose(context)
                    
                    // remember to delete the temp folder
                    
                }
            }
        }
        
    }
    
    // helper function translating col number to excel column index
    func toExcelCol(colNum: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        if colNum < 26 {
            return letters[colNum]
        }
        else {
            return toExcelCol(colNum / 26 - 1) + toExcelCol(colNum % 26)
        }
    }
    
}

