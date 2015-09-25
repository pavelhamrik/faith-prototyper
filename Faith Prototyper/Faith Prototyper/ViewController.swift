//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //let sysTmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
    var tmpDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("faithprototyper")
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print(tmpDirURL)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded. 
        }
    }
    
    
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
                    let fileURL = self.tmpDirURL.URLByAppendingPathComponent("xl/worksheets/sheet10.xml")
                    let xmlToParse = try! NSString(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
                    //print(xmlToParse)
                    let xml = SWXMLHash.parse(xmlToParse as String)
                    
                    for row in xml["worksheet"]["sheetData"]["row"] {
                        for cell in row["c"] {
                            //print(cell)
                            print(cell["v"].element?.text)
                        }
                        print("----------")
                    }
                    
                    //print(xml["worksheet"]["sheetData"])
                    
                    
                    // https://github.com/drmohundro/SWXMLHash
                    
                    // https://github.com/nicklockwood/XMLDictionary
                    // JS XLSX parser http://bl.ocks.org/lancejpollard/3808517
                    // http://blogs.msdn.com/b/brian_jones/archive/2007/05/29/simple-spreadsheetml-file-part-3-formatting.aspx
                    
                    
                    
                    
                } catch {
                    print("Failed to create the file.")
                }
                
                // Rest

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
}

