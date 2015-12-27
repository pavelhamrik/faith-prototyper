//
//  CardTable.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 28.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class CardTable: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    
    var rows: [NSMutableDictionary] = [
        ["Name": "Load some cards..."]
    ]
    
    @IBOutlet var tableView: NSTableView!
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "act:", name:"refreshCardTableView", object: nil)
        
        self.rows = Helpers.loadDefaultsDictionary("DefaultCards")
        fillTable()

    }
    
    
    func act(notification: NSNotification) {
        
        let userinfo = notification.userInfo
        self.rows = userinfo?["rows"] as! [NSMutableDictionary]
        
        Helpers.saveDefaultsDictionary("DefaultCards", dictionary: self.rows)
        
        fillTable()
    }
    
    
    func fillTable() {
        
        /*
        let tableCols = self.tableView.tableColumns
        for col in tableCols {
            self.tableView.removeTableColumn(col)
        }
        
        for (key, _) in self.rows[0] {
            let column = NSTableColumn()
            column.title = key as! String
            column.identifier = key as! String
            self.tableView.addTableColumn(column)
        }
        
        self.tableView.reloadData()
        */
        
        // TMP
        //print(self.tableView.numberOfRows)
    }
    

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        
        let numberOfRows:Int = getDataArray().count
        return numberOfRows
    }
    
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        let newString = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
        return newString;
        
    }
    
    
    func getDataArray() -> NSArray {
        
        var regularRows = self.rows
        regularRows.removeAtIndex(0)
        return regularRows;
        
    }
 
    
}
