//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    var rows: [NSMutableDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(tmpDirURL)
        
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
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshCardTableView", object: nil, userInfo:["rows": self.rows])
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
                    
                    // page size
                    let pgxsize = CGFloat(595.0)
                    let pgysize = CGFloat(842.0)
                    
                    // card size
                    let cardxsize = CGFloat(self.mm2pt(63))
                    let cardysize = CGFloat(self.mm2pt(88))
                    
                    // page layout
                    let cardxgutter = CGFloat(self.mm2pt(3))
                    let cardygutter = CGFloat(self.mm2pt(3))
                    let minpgxmargin = CGFloat(self.mm2pt(5))
                    let minpgymargin = CGFloat(self.mm2pt(8))
                    
                    var pageSize = CGRect(x: 0.0, y: 0.0, width: pgxsize, height: pgysize)
                    
                    let cardsperx = floor((pgxsize - (2 * minpgxmargin) + cardxgutter) / (cardxsize + cardxgutter))
                    let cardspery = floor((pgysize - (2 * minpgymargin) + cardygutter) / (cardysize + cardygutter))
                    
                    let pgxmargin = (pgxsize - ((cardsperx * cardxgutter - cardxgutter) + (cardsperx * cardxsize))) / 2
                    let pgymargin = (pgysize - ((cardspery * cardygutter - cardygutter) + (cardspery * cardysize))) / 2
                    
                    // context
                    let context = CGPDFContextCreateWithURL(exportedFileURL, &pageSize, nil)
                    
                    // temporary workaround
                    if (self.rows.count < 1) {
                        for _ in 1...12 {
                            self.rows.append(["fname": "A", "lname": "B"])
                        }
                    }
                    // /temporary workaround
                    
                    let pgnums = Int(ceil(CGFloat(self.rows.count) / (cardsperx * cardspery)))
                    for var pgnum = 0; pgnum < pgnums; pgnum += 1 {
                        CGPDFContextBeginPage(context, nil)
                        for var pgrow = CGFloat(0.0); pgrow < cardsperx; pgrow += 1 {
                            for var pgcol = CGFloat(0.0); pgcol < cardspery; pgcol += 1 {
                                
                                var cardxbound = CGFloat(cardxsize * pgcol + pgxmargin)
                                if (pgcol >= CGFloat(1)) {
                                    cardxbound += cardxgutter * pgcol
                                }
                                var cardybound = CGFloat(cardysize * pgrow + pgymargin)
                                if (pgrow >= CGFloat(1)) {
                                    cardybound += cardygutter * pgrow
                                }
                                
                                
                                let pagesIndexRise = (cardsperx * cardspery * CGFloat(pgnum))
                                let cardindex = pagesIndexRise + pgrow * cardsperx + pgcol + 1
                                
                                if (cardindex >= CGFloat(self.rows.count)) {
                                    break
                                }
                                
                                self.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                                
                                if (pgrow == CGFloat(0) && pgcol == CGFloat(0)) {
                                    self.drawShape("fillrect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                                }
                                
                                let textAttributes = ["font": "Lato", "size": "18", "weight": "Light", "color": "black"]
                                self.drawShape("textframe", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, text: self.rows[Int(cardindex)]["Name"] as! String, textattributes: textAttributes)
                                
                            } // pgrows
                        } // pgcols
                        
                        CGPDFContextEndPage(context)
                    } // pages
                    
                    CGPDFContextClose(context)
                    
                    // TODO: remember to delete the temp folder
                    
                }
            }
        }
        
    }
    
    // helper function transforming mm to quartz 2d pt
    
    func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        drawShape(shape, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, text: "", textattributes: ["": ""])
    }
    
    func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, text: String) {
        drawShape(shape, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, text: text, textattributes: ["": ""])
    }
    
    func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, text: String, textattributes: [String: String]) {
        let thinline = CGFloat(0.25)
        // colors as params; params as array/dictionary?
        
        switch shape {
            
        case "linerect":
            CGContextSetLineWidth(context, thinline)
            CGContextSetStrokeColorWithColor(context, NSColor.redColor().CGColor)
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextStrokePath(context)
            
        case "fillrect":
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextSetRGBFillColor (context, 1, 0, 0, 1)
            CGContextFillPath(context)
            
        case "textframe":
            var font = NSFont(name: "Lato", size: 10.0)
            if (textattributes["font"] != nil) {
                font = NSFont(name: textattributes["font"]!, size: 10.0)
            }
            if (textattributes["weight"] != nil) {
                let fontNameWithWeight = font!.fontName.componentsSeparatedByString("-").first! + "-" + textattributes["weight"]!
                font = NSFont(name: fontNameWithWeight, size: 10.0)
            }
            if (textattributes["size"] != nil) {
                let customsize = textattributes["size"]! as NSString
                font = NSFont(name: font!.fontName, size: CGFloat(customsize.intValue))
            }
            
            
            let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            let textColor = NSColor.blackColor()
            
            let textFontAttributes = [
                NSFontAttributeName : font!,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: textStyle
            ]
            
            CGContextSetTextMatrix(context, CGAffineTransformIdentity)
            
            let attributedString = NSMutableAttributedString(string: text, attributes: textFontAttributes)
            
            let framesetter =  CTFramesetterCreateWithAttributedString(attributedString);
            let path = CGPathCreateWithRect(CGRectMake(xfrom, yfrom, xsize, ysize), nil);
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
            CTFrameDraw(frame, context);
            
            

            
            
            
        default:
            break
        }
        
    }
    
    
    func mm2pt(mm: CGFloat) -> CGFloat {
        let ratio = 2.8333
        return CGFloat(mm * CGFloat(ratio))
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

