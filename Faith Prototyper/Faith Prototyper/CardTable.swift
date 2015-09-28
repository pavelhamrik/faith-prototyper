//
//  CardTable.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 28.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class CardTable: NSViewController, NSTableViewDelegate, NSTableViewDataSource, cardTableViewProtocol {
    
    var rows: [NSMutableDictionary] = [
        ["Name": "Many Hellos!"]
    ]
    
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "act:", name:"refreshCardTableView", object: nil)
    }
    
    func act(notification: NSNotification) {
        print("I'm here")
        print(rows)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "cardTableSubview" {
            let target = segue.destinationController as? ViewController
            print(segue.sourceController)
            print(target)
            target!.delegate = self;
        }
    }
    
    func updateCardTableView(update: AnyObject, value: AnyObject) {
        print("I'm here")
        print(update)
        self.tableView.reloadData()
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
        return rows;
    }
    
}
