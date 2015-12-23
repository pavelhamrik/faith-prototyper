//
//  PDFExporter.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class PDFExporter {
    
    
    static func generate(fileURL: NSURL, var rows: [NSMutableDictionary]) {
        
        // page size
        
        let pgxsize = CGFloat(595.0)
        let pgysize = CGFloat(842.0)
        
        
        // card size
        
        let cardxsize = CGFloat(ShapeDrawer.mm2pt(63))
        let cardysize = CGFloat(ShapeDrawer.mm2pt(88))
        
        
        // page layout
        
        let cardxgutter = CGFloat(ShapeDrawer.mm2pt(3))
        let cardygutter = CGFloat(ShapeDrawer.mm2pt(3))
        let minpgxmargin = CGFloat(ShapeDrawer.mm2pt(5))
        let minpgymargin = CGFloat(ShapeDrawer.mm2pt(8))
        
        var pageSize = CGRect(x: 0.0, y: 0.0, width: pgxsize, height: pgysize)
        
        let cardsperx = floor((pgxsize - (2 * minpgxmargin) + cardxgutter) / (cardxsize + cardxgutter))
        let cardspery = floor((pgysize - (2 * minpgymargin) + cardygutter) / (cardysize + cardygutter))
        
        let pgxmargin = (pgxsize - ((cardsperx * cardxgutter - cardxgutter) + (cardsperx * cardxsize))) / 2
        let pgymargin = (pgysize - ((cardspery * cardygutter - cardygutter) + (cardspery * cardysize))) / 2
        
        
        // context, static image sources
        
        let context = CGPDFContextCreateWithURL(fileURL, &pageSize, nil)
        let cardBackSource = CGImageSourceCreateWithURL(NSURL(string: "file:///Users/pavelhamrik/Dropbox/Public/faith/mac/background_Grey.png")! as CFURL, nil)
        var frame = [CGFloat(0.0), CGFloat(0.0), CGFloat(50.0), CGFloat(10.0)]
        
        
        // filtering by preferences
        
        let defaultTypes = Helpers.loadDefaults("prefsExportTypes")
        if (!(defaultTypes ?? "").isEmpty) {
            rows = Helpers.filterByArray(rows, filter: defaultTypes, column: "Type")
        }
        
        let defaultGroups = Helpers.loadDefaults("prefsExportGroups")
        if (!(defaultGroups ?? "").isEmpty) {
            rows = Helpers.filterByArray(rows, filter: defaultGroups, column: "Group")
        }
        
        let defaultStatuses = Helpers.loadDefaults("prefsExportStatuses")
        if (!(defaultStatuses ?? "").isEmpty) {
            rows = Helpers.filterByArray(rows, filter: defaultStatuses, column: "Status")
        }
        
        let defaultPrintings = Helpers.loadDefaults("prefsExportPrintings")
        if (!(defaultPrintings ?? "").isEmpty) {
            rows = Helpers.filterByArray(rows, filter: defaultPrintings, column: "Printing")
        }
        
        let defaultFactions = Helpers.loadDefaults("prefsExportFactions")
        if (!(defaultFactions ?? "").isEmpty) {
            rows = Helpers.filterByArray(rows, filter: defaultFactions, column: "Factions")
        }
        
        
        // card by card output
        
        let pgnums = Int(ceil(CGFloat(rows.count) / (cardsperx * cardspery)))
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
                    
                    if (cardindex >= CGFloat(rows.count)) {
                        break
                    }
                    
                    
                    // draw backgrounds from previously downloaded CFImageSource
                    ShapeDrawer.drawImageFromSource(cardBackSource!, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    
                    
                    // TODO: Draw a card image if found
                    //ShapeDrawer.drawImageFromURL(NSURL(string: "file:///Users/pavelhamrik/Dropbox/Public/faith/mac/background_Grey.png")!, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)

                    
                    // draw the card frame
                    ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    
                    
                    // typeset card name
                    frame = [CGFloat(31.5), CGFloat(10.5), CGFloat(138.0), CGFloat(30.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: rows[Int(cardindex)]["Name"] as! String,
                        textattributes: ["font": "Adelle", "size": "9", "weight": "Bold", "color": "black"]
                    )
                    
                    // typeset card type, descent and class
                    // TODO: classes, attributed string, bullet as connector, font weights for classes
                    frame = [CGFloat(31.5), CGFloat(22.5), CGFloat(138.0), CGFloat(30.0)]
                    
                    var typeAndClasses = rows[Int(cardindex)]["Type"] as! String
                    
                    let descent = String(rows[Int(cardindex)]["Descent"])
                    if (!(descent ?? "").isEmpty) {
                        if (descent != "None") {
                            typeAndClasses += " \u{2022} " + (rows[Int(cardindex)]["Descent"] as! String)
                        }
                    }
                    
                    let classCol = String(rows[Int(cardindex)]["Descent"])
                    if (!(classCol ?? "").isEmpty) {
                        if (classCol != "None") {
                            typeAndClasses += " " + (rows[Int(cardindex)]["Class"] as! String)
                        }
                    }
                    
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: typeAndClasses,
                        textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"]
                    )
                    
                    
                    // typeset card text
                    // TODO: attributed string, icons, etc.
                    frame = [CGFloat(31.5), CGFloat(164.0), CGFloat(138.0), CGFloat(70.0)]
                    
                    var abilities = (rows[Int(cardindex)]["Ability 1 Cost"] as! String) + ": "
                    abilities += (rows[Int(cardindex)]["Ability 1"] as! String)
                    abilities += (rows[Int(cardindex)]["Ability 2 Cost"] as! String) + ": "
                    abilities += (rows[Int(cardindex)]["Ability 2"] as! String)
                    abilities += (rows[Int(cardindex)]["Ability 3 Cost"] as! String) + ": "
                    abilities += (rows[Int(cardindex)]["Ability 3"] as! String)
                    abilities += "Achieved \r\n" + (rows[Int(cardindex)]["Achieved Ability Cost"] as! String) + ": "
                    abilities += (rows[Int(cardindex)]["Achieved Ability"] as! String)
                    
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: abilities,
                        textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black", "lineSpacing": "0.0"]
                    )
                    
                    
                    // typeset card claim
                    frame = [CGFloat(10.5), CGFloat(11.0), CGFloat(16.0), CGFloat(140.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(rows[Int(cardindex)]["Claim"] as! String, purpose: "generalMasking"),
                        textattributes: ["font": "FaithIcons", "size": "11", "color": "white", "lineSpacing": "1"] // do not include weight as the custom font apparently doesn't have one
                    )
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(rows[Int(cardindex)]["Claim"] as! String, purpose: "general"),
                        textattributes: ["font": "FaithIcons", "size": "11", "color": "black", "lineSpacing": "1"] // do not include weight as the custom font apparently doesn't have one
                    )

                    // typeset scheme difficulty
                    // ...
                    
                    
                    // typeset card belief
                    // ...
                    
                    
                    // typeset meta information incl. icon
                    // ...
                    
                    
                    // typeset artist incl. icon
                    // ...
                    
                    
                } // pgrows
            } // pgcols
            
            CGPDFContextEndPage(context)
            
        } // pages
        
        CGPDFContextClose(context)
    
    }
    
}
