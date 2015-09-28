//
//  cardTableDelegate.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 26.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class cardTableDelegate: NSViewController, NSTableViewDelegate, NSTableViewDataSource, cardTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var rows = [NSMutableDictionary]()
    
    func updateCardTableView(sender: AnyObject) {
        print("delegate very much pinged")
        self.tableView.reloadData()
    }
    
    
    /*override func viewDidLoad() {
        super.viewDidLoad()
        
        print("hello")
        
        //tableView.setDelegate(self.tableView.delegate())
        //self.tableView.setDataSource(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList:", name:"refreshMyTableView", object: nil)
        
        let keys = Array(arrayLiteral: "Name")
        let keyset = NSDictionary.sharedKeySetForKeys(keys)
        let cell = NSMutableDictionary(sharedKeySet: keyset)
        
        cell.setObject("Hello", forKey: "Name")
        rows.append(cell)
        
        tableView.reloadData()
    }

    
    func refreshList(notification: NSNotification){
        let keys = Array(arrayLiteral: "Name")
        let keyset = NSDictionary.sharedKeySetForKeys(keys)
        let cell = NSMutableDictionary(sharedKeySet: keyset)
        
        cell.setObject("Hello2", forKey: "Name")
        rows.append(cell)
        
        if self.tableView != nil {
            //self.tableView.reloadData()
            print("tw not nil")
        }
        print("even here notified")
    }*/
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let numberOfRows:Int = getDataArray().count
        return numberOfRows
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let newString = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
        return newString;
    }
    
    func getDataArray () -> NSArray {
        rows = [
            ["Name": "Hello"]
        ]
        return rows;
    }
    
}
