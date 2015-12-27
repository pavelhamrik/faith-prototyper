//
//  ZipZap.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 26.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ZipZapHelpers {
    
    // ZipZap Doc https://github.com/pixelglow/zipzap

    static func unzip(fileURL: NSURL, tmpDirURL: NSURL) -> Bool {
        
        do {
            
            let archive: ZZArchive = try ZZArchive(URL: fileURL)
            let fileManager = NSFileManager.defaultManager()
            
            for index in 1...archive.entries.count {
                
                let entry = archive.entries[index-1]
                let entryURL = tmpDirURL.URLByAppendingPathComponent(entry.fileName)
                
                try! fileManager.createDirectoryAtURL(entryURL.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
                try! entry.newData().writeToURL(entryURL, atomically: false)
                
                return true
                
            }
            
        }
        catch {
            
            print("Failed to unpack the XLSX.")
            
        }
        
        return false
    
    }

}
