//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

protocol cardTableViewDelegate {
    func updateCardTableView()
    var rows: [NSMutableDictionary]{get set}
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, cardTableViewDelegate {
    
    //let sysTmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
    var tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    var rows = [NSMutableDictionary]()
//    var delegate: cardTableViewDelegate = cardTableDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(tmpDirURL)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList:", name:"refreshMyTableView", object: nil)

        //tableView.setDelegate(self.tableView.delegate())
        //self.tableView.setDataSource(self)
        
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        //if let controller = segue.destinationController as? NSTableView {
            //controller.setDelegate(self.tableView.delegate())
            //print(self.tableView.delegate())
        //}
    }
    
    func updateCardTableView() {
        
    }
    
    func refreshList(notification: NSNotification){
        print("pressed-notified")
        //delegate.updateCardTableView()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded. 
        }
    }
    
    // handle the main table
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let numberOfRows:Int = getDataArray().count
        return numberOfRows
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let newString = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
        return newString;
    }
    
    func getDataArray () -> NSArray {
        return self.rows;
    }
    
    
    // load the xlsx
    
    @IBAction func loadData(sender : AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["xlsx"]
        openPanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let importFileURL = openPanel.URL
                
                // Unzip the shit out of it
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
                    
                    // parsing
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
                    //print(sheets)

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
                        // first worksheet, redo dynamically
                        xmlURL = self.tmpDirURL.URLByAppendingPathComponent("xl/" + value)
                        xmlToParse = try! NSString(contentsOfURL: xmlURL, encoding: NSUTF8StringEncoding)
                        let xml = SWXMLHash.parse(xmlToParse as String)
                        let row = xml["worksheet"]["sheetData"]["row"][0]
                        var localKeys = [String]()
                        for col in row["c"] {
                            if col["v"].element?.text != nil {
                                let index = Int((col["v"].element?.text)!)
                                localKeys.append(sharedStrings[index!])
                            }
                        }
                        //print(localKeys)
                        for xmlRow in xml["worksheet"]["sheetData"]["row"] {
                            let cell = NSMutableDictionary(sharedKeySet: keyset)
                            var colNum = 0
                            let colCount = localKeys.count
                            //print(colCount)
                            var empty = true
                            for xmlCell in xmlRow["c"] {
                                //print(colNum)
                                if colNum >= colCount {
                                    break
                                }
                                // <c r="D4" s="15" t="s">, <c r="E4" s="77" t="str"> (formula)
                                if xmlCell.element?.attributes["t"] == "s" {
                                    // fetch the referenced s
                                    let index = Int((xmlCell["v"].element?.text)!)
                                    cell.setObject(sharedStrings[index!], forKey: localKeys[colNum])
                                    empty = false
                                } else if xmlCell.element?.attributes["t"] == "str" {
                                    // here we just use the value
                                    cell.setObject((xmlCell["v"].element?.text)!, forKey: localKeys[colNum])
                                    empty = false
                                } else {
                                    cell.setObject("--", forKey: localKeys[colNum])
                                }
                                colNum += 1
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
    
    @IBAction func printVar(sender: AnyObject) {
        print("pressed")
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMyTableView", object: nil)
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
}

