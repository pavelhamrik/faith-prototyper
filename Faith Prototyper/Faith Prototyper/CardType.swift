//
//  CardTypeDelegate.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 25.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class CardType: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet var textField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let numberOfRows:Int = getDataArray().count
        return numberOfRows
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let newString = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
        return newString;
    }
    
    func getDataArray () -> NSArray{
        let dataArray:[NSDictionary] = [
            ["CardType": "Myths"],
            ["CardType": "Schemes"],
            ["CardType": "Events"],
            ["CardType": "Attachments"]
        ];
        return dataArray;
    }

    
}
