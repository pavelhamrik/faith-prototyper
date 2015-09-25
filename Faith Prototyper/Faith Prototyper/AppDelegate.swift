//
//  AppDelegate.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 21.09.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {

    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int
    {
        let numberOfRows:Int = getDataArray().count
        return numberOfRows
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
    {
        let newString = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
        return newString;
    }
    
    func getDataArray () -> NSArray{
        let dataArray:[NSDictionary] = [
            ["FirstName": "Debasis",    "LastName": "Das"],
            ["FirstName": "Nishant",    "LastName": "Singh"],
            ["FirstName": "John",       "LastName": "Doe"],
            ["FirstName": "Jane",       "LastName": "Doe"],
            ["FirstName": "Mary",       "LastName": "Jane"]
        ];
        //print(dataArray);
        return dataArray;
    }
    
    
}

