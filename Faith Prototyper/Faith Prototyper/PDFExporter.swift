//
//  PDFExporter.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class PDFExporter {
    
    
    static func preformatCost(cost: String) -> NSAttributedString {
        
        let output = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
        
        if !(cost ?? "").isEmpty {
            if String(cost) != "None" {
                
                let normalizedCost = cost.stringByReplacingOccurrencesOfString(", ", withString: ",")
                let splitCosts = normalizedCost.characters.split{$0 == ","}.map(String.init)
                var elements = [NSAttributedString]()
                
                for splitCost in splitCosts {
                    let matches = Helpers.matchesForRegexInText("([FCVRMI0-9]+(?=,|\\s|$))", text: splitCost)
                    if matches.count > 0 {
                        for match in matches {
                            if match.count > 1 {
                                for index in 1...match.count - 1 {
                                    elements.append(ShapeDrawer.attributedCompose(ShapeDrawer.iconize(match[index]), textattributes: ["font": "FaithIcons", "size": "6", "color": "black", "kerning": "0.5", "paragraphSpacingAfter": "3.0"]))
                                }
                            }
                        }
                    }
                    else {
                        elements.append(ShapeDrawer.attributedCompose(splitCost, textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black", "paragraphSpacingAfter": "3.0"]))
                    }
                }
                
                let separator = ShapeDrawer.attributedCompose(", ", textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black", "paragraphSpacingAfter": "3.0"])
                output.appendAttributedString(elements.joinWithSeparator(separator))
                output.appendAttributedString(ShapeDrawer.attributedCompose(": ", textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black", "paragraphSpacingAfter": "3.0"]))
                
            }
        }
        
        return output
        
    }
    
    
    static func preformatEffect(effect: String) -> NSAttributedString {
        
        let output = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
        
        if !(effect ?? "").isEmpty {
            if String(effect) != "None" {
                
                let effectAttributed = ShapeDrawer.attributedCompose(effect, textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black", "paragraphSpacingAfter": "3.0"])
                let matches = Helpers.matchesWithRangesForRegexInAttributedText("(\\(.*\\))", text: effectAttributed)
                
                for match in matches {
                    if match.count > 1 {
                        for index in 1...match.count - 1 {
                            let (value, range) = match[index]
                            let replacement = ShapeDrawer.attributedCompose(value, textattributes: ["font": "Lato", "size": "7", "weight": "LightItalic", "color": "black", "paragraphSpacingAfter": "3.0"])
                            effectAttributed.replaceCharactersInRange(range, withAttributedString: replacement)
                        }
                    }
                }
                
                output.appendAttributedString(effectAttributed)
                output.appendAttributedString(ShapeDrawer.attributedCompose("\u{2029}", textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black", "paragraphSpacingAfter": "3.0"]))
            }
        }
        
        return output
        
    }
    
    
    static func generate(fileURL: NSURL, var rows: [[String: String]]) {
        
        
        // page size
        
        let pgxsize = CGFloat(595.0)
        let pgysize = CGFloat(842.0)
        
        
        // card size
        
        let cardxsize = CGFloat(ShapeDrawer.mm2pt(63))
        let cardysize = CGFloat(ShapeDrawer.mm2pt(88))
        
        
        // page layout
        
        
        // load defaults for card x & y spacing
        
        var cardxgutter = CGFloat(ShapeDrawer.mm2pt(3))
        let defaultCardXSpacing = Helpers.loadDefaults("prefsExportCardXSpacing")
        if (!(defaultCardXSpacing ?? "").isEmpty) {
            let nsDefaultCardXSpacing = defaultCardXSpacing as NSString
            cardxgutter = CGFloat(ShapeDrawer.mm2pt(CGFloat(nsDefaultCardXSpacing.floatValue)))
        }
        
        var cardygutter = CGFloat(ShapeDrawer.mm2pt(3))
        let defaultCardYSpacing = Helpers.loadDefaults("prefsExportCardYSpacing")
        if (!(defaultCardYSpacing ?? "").isEmpty) {
            let nsDefaultCardYSpacing = defaultCardYSpacing as NSString
            cardygutter = CGFloat(ShapeDrawer.mm2pt(CGFloat(nsDefaultCardYSpacing.floatValue)))
        }
        
        
        // computing the rest of card spacing
        
        let minpgxmargin = CGFloat(ShapeDrawer.mm2pt(5))
        let minpgymargin = CGFloat(ShapeDrawer.mm2pt(8))
        
        var pageSize = CGRect(x: 0.0, y: 0.0, width: pgxsize, height: pgysize)
        
        let cardsperx = floor((pgxsize - (2 * minpgxmargin) + cardxgutter) / (cardxsize + cardxgutter))
        let cardspery = floor((pgysize - (2 * minpgymargin) + cardygutter) / (cardysize + cardygutter))
        
        let pgxmargin = (pgxsize - ((cardsperx * cardxgutter - cardxgutter) + (cardsperx * cardxsize))) / 2
        let pgymargin = (pgysize - ((cardspery * cardygutter - cardygutter) + (cardspery * cardysize))) / 2
        
        
        // context, static image sources
        
        let context = CGPDFContextCreateWithURL(fileURL, &pageSize, nil)
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
        
        
        // additional global settings
        
        var printFrameAllPages = false
        let defaultExportFrameAllPages = Helpers.loadDefaults("prefsExportFrameAllPages")
        if !(defaultExportFrameAllPages ?? "").isEmpty {
            if (defaultExportFrameAllPages as NSString).integerValue == NSOnState {
                printFrameAllPages = true
            }
        }
        
        
        // print template page, if requested by the user
        
        let defaultExportFrameTemplatePage = Helpers.loadDefaults("prefsExportFrameTemplatePage")
        if !(defaultExportFrameTemplatePage ?? "").isEmpty {
            if (defaultExportFrameTemplatePage as NSString).integerValue == NSOnState {
                
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
                        ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    }
                }
                
                CGPDFContextEndPage(context)
                
            }
        }
        
        
        // copyright note from defaults
        
        var copyrightNote = ""
        let defaultCopyrightNote = Helpers.loadDefaults("prefsExportCopyrightNote")
        if !(defaultCopyrightNote ?? "").isEmpty {
            copyrightNote = defaultCopyrightNote
        }
        
        
        // card by card output
        
        let pgnums = Int(ceil(CGFloat(rows.count) / (cardsperx * cardspery)))
        for var pgnum = 0; pgnum < pgnums; pgnum += 1 {
            
            CGPDFContextBeginPage(context, nil)
            
            for var pgrow = CGFloat(0.0); pgrow < cardsperx; pgrow += 1 {
                for var pgcol = CGFloat(0.0); pgcol < cardspery; pgcol += 1 {
                    
                    
                    // computing the card bounds for the current interation
                    
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
                    
                    
                    // simplify getting the current row
                    
                    let row = rows[Int(cardindex)]
                    
                    
                    // draw backgrounds from asset catalog
                    
                    ShapeDrawer.drawImageFromAssetCatalog("background_Grey", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    
                    
                    // TODO: Draw a card image if found
                    
                    //ShapeDrawer.drawImageFromURL(NSURL(string: "file:///Users/pavelhamrik/Dropbox/Public/faith/mac/background_Grey.png")!, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)

                    
                    // draw the card frame
                    
                    if printFrameAllPages {
                        ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    }
                    
                    // typeset card name
                    
                    frame = [CGFloat(31.5), CGFloat(10.5), CGFloat(138.0), CGFloat(30.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: row["Name"]!,
                        textattributes: ["font": "Roboto Slab", "size": "9", "weight": "Bold", "color": "black"]
                    )
                    
                    
                    // typeset card type, descent and class
                    
                    frame = [CGFloat(31.5), CGFloat(22.0), CGFloat(138.0), CGFloat(30.0)]
                    
                    let typeAndClasses = ShapeDrawer.attributedCompose("", textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"])
                    
                    if (!(String(row["Playtype"]) ?? "").isEmpty) {
                        if (String(row["Playtype"]!) != "None" && !String(row["Playtype"]!).isEmpty) {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(String(row["Playtype"]!) + " ", textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"]))
                        }
                    }
                    
                    if !(row["Type"] ?? "").isEmpty {
                        if String(row["Type"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(String(row["Type"]!), textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"]))
                        }
                    }
                    
                    if !(row["Subtype"] ?? "").isEmpty {
                        if String(row["Subtype"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose("\u{2014}" + String(row["Subtype"]!), textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"]))
                        }
                    }
                    
                    var printBullet = false
                    if !(row["Descent"] ?? "").isEmpty {
                        if String(row["Descent"]!) != "None" {
                            printBullet = true
                        }
                    }
                    if !(row["Class"] ?? "").isEmpty {
                        if String(row["Class"]!) != "None" {
                            printBullet = true
                        }
                    }
                    if printBullet {
                        typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" \u{2022}", textattributes: ["font": "Lato", "size": "7", "weight": "Thin", "color": "black"]))
                    }
                    
                    if !(row["Descent"] ?? "").isEmpty {
                        if String(row["Descent"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" " + String(row["Descent"]!), textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black"]))
                        }
                    }
                    
                    if !(row["Class"] ?? "").isEmpty {
                        if String(row["Class"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" " + String(row["Class"]!), textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black"]))
                        }
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        typeAndClasses,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )
                    
                    
                    // typeset card text
                    
                    frame = [CGFloat(31.5), CGFloat(164.0), CGFloat(138.0), CGFloat(70.0)]
                    
                    let abilities = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
                    
                    if !(row["Ability 1 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 1 Cost"]!))
                    }
                    if !(row["Ability 1"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 1"]!))
                    }
                    if !(row["Ability 2 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 2 Cost"]!))
                    }
                    if !(row["Ability 2"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 2"]!))
                    }
                    if !(row["Ability 3 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 3 Cost"]!))
                    }
                    if !(row["Ability 3"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 3"]!))
                    }
                    if !(row["Achieved Ability"] ?? "").isEmpty {
                        if String(row["Achieved Ability"]!) != "None" {
                            abilities.appendAttributedString(ShapeDrawer.attributedCompose("ACHIEVED\u{000a}", textattributes: ["font": "Lato", "size": "5", "weight": "Bold", "color": "gray", "paragraphSpacingAfter": "1.0"]))
                        }
                    }
                    if !(row["Achieved Ability Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Achieved Ability Cost"]!))
                    }
                    if !(row["Achieved Ability"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Achieved Ability"]!))
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        abilities,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )
                    
                    
                    // typeset card claim
                    
                    frame = [CGFloat(10.5), CGFloat(11.5), CGFloat(16.0), CGFloat(140.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(row["Claim"]!, purpose: "generalMasking"),
                        textattributes: ["font": "FaithIcons", "size": "11", "color": "white", "lineSpacing": "1.1"] // do not include weight as the custom font apparently doesn't have one
                    )
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(row["Claim"]!, purpose: "general"),
                        textattributes: ["font": "FaithIcons", "size": "11", "color": "black", "lineSpacing": "1.1"]
                    )

                    
                    // typeset scheme difficulty
                    
                    if !(row["Difficulty"] ?? "").isEmpty {
                        frame = [CGFloat(6.75), CGFloat(213.5), CGFloat(20.0), CGFloat(140.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Difficulty"]!, purpose: "difficultyMasking"),
                            textattributes: ["font": "FaithIcons", "size": "18", "color": "white", "lineSpacing": "1.1"]
                        )
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Difficulty"]!, purpose: "difficulty"),
                            textattributes: ["font": "FaithIcons", "size": "18", "color": "black", "lineSpacing": "1.1"]
                        )
                    }
                    
                    
                    // typeset myth/follower power
                    
                    if !(row["Power"] ?? "").isEmpty {
                        frame = [CGFloat(7.75), CGFloat(214.5), CGFloat(20.0), CGFloat(140.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Power"]!, purpose: "powerMasking"),
                            textattributes: ["font": "FaithIcons", "size": "16", "color": "white", "lineSpacing": "1.1"]
                        )
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Power"]!, purpose: "power"),
                            textattributes: ["font": "FaithIcons", "size": "16", "color": "black", "lineSpacing": "1.1"]
                        )
                    }
                    
                    
                    // typeset card belief
                    
                    if !(row["Belief"] ?? "").isEmpty {
                        frame = [CGFloat(10.0), CGFloat(163.0), CGFloat(20.0), CGFloat(140.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Belief"]!, purpose: "beliefMasking"),
                            textattributes: ["font": "FaithIcons", "size": "12", "color": "white", "lineSpacing": "1.1"]
                        )
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: ShapeDrawer.iconize(row["Belief"]!, purpose: "belief"),
                            textattributes: ["font": "FaithIcons", "size": "12", "color": "black", "lineSpacing": "1.1"]
                        )
                    }
                    
                    
                    // typeset lock icon
                    
                    frame = [CGFloat(31.5), CGFloat(237), CGFloat(16.0), CGFloat(140.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize("l", purpose: "general"),
                        textattributes: ["font": "FaithIcons", "size": "9", "color": "gray"]
                    )
                    
                    
                    // typeset meta
                    
                    frame = [CGFloat(42.0), CGFloat(236.0), CGFloat(138.0), CGFloat(70.0)]
                    let meta = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
                    let metaLineSpacing = "0.1"
                    
                    if !(copyrightNote ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(copyrightNote.uppercaseString, textattributes: ["font": "Lato", "size": "4", "weight": "Regular", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2029}", textattributes: ["font": "Lato", "size": "4", "weight": "Regular", "color": "black", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    meta.appendAttributedString(ShapeDrawer.attributedCompose(Helpers.getFormattedNow().uppercaseString, textattributes: ["font": "Lato", "size": "4", "weight": "Regular", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    
                    if !(row["Printing"] ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2005}\u{2022}\u{2005}", textattributes: ["font": "Lato", "size": "4", "weight": "Thin", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(row["Printing"]!.uppercaseString, textattributes: ["font": "Lato", "size": "4", "weight": "Regular", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    if !(row["Status"] ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2005}\u{2022}\u{2005}", textattributes: ["font": "Lato", "size": "4", "weight": "Thin", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(row["Status"]!.uppercaseString, textattributes: ["font": "Lato", "size": "4", "weight": "Regular", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        meta,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )

                    
                    // typeset artist incl. icon
                    // ...
                    
                    
                } // pgrows
            } // pgcols
            
            CGPDFContextEndPage(context)
            
        } // pages
        
        CGPDFContextClose(context)
    
    }
    
}
