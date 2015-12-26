//
//  ViewController.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate {
    
    
    var window = NSWindow()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        window = NSApplication.sharedApplication().windows[0] as NSWindow
        window.delegate = self;
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    
    // load the xlsx
    // TODO: remember to delete the temp folder at the end
    @IBAction func loadData(sender: AnyObject) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["xlsx"]
        openPanel.beginWithCompletionHandler { (result: Int) -> Void in

            if result == NSFileHandlingPanelOKButton {
                if openPanel.URL != nil {
                    let rows = XLSX.parse(openPanel.URL!)
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshCardTableView", object: nil, userInfo:["rows": rows])
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
                    
                    PDFExporter.generate(exportedFileURL!, rows: Helpers.loadDefaultsDictionary("DefaultCards"))
                    
                }
            }
        }
        
    }
    
}
