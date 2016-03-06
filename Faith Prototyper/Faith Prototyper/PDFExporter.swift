//
//  PDFExporter.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa
import Foundation

class PDFExporter {
    
    
    static var fontFamily = "Lato"
    static let requiredFontWeights = [
        ["Book", "Book", "300"],
        ["BookItalic", "BookItalic", "300Italic"],
        ["Medium", "400"],
        ["MediumItalic", "400Italic"],
        ["Bold", "700"],
        ["BoldItalic", "700Italic"]
    ]
    static let imageFormatExtensions = [
        "", // in case the filename already includes the extension
        ".jpg",
        ".jpeg",
        ".png"
    ]
    
    
    static func preformatCost(cost: String, spacingBefore: String) -> NSAttributedString {
        
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
                                    elements.append(ShapeDrawer.attributedCompose(ShapeDrawer.iconize(match[index]), textattributes: ["font": "FaithIcons", "size": "5.5", "color": "black", "kerning": "0.5", "paragraphSpacingBefore": spacingBefore]))
                                }
                            }
                        }
                    }
                    else {
                        elements.append(ShapeDrawer.attributedCompose(splitCost, textattributes: ["font": PDFExporter.fontFamily, "size": "6.5", "weight": "Bold", "color": "black", "paragraphSpacingBefore": spacingBefore]))
                    }
                }
                
                let separator = ShapeDrawer.attributedCompose(", ", textattributes: ["font": PDFExporter.fontFamily, "size": "6.5", "weight": "Bold", "color": "black", "paragraphSpacingBefore": spacingBefore])
                output.appendAttributedString(elements.joinWithSeparator(separator))
                output.appendAttributedString(ShapeDrawer.attributedCompose(": ", textattributes: ["font": PDFExporter.fontFamily, "size": "6.5", "weight": "Bold", "color": "black", "paragraphSpacingBefore": spacingBefore]))
                
            }
        }
        
        return output
        
    }
    
    
    static func preformatEffect(effect: String, spacingBefore: String) -> NSAttributedString {
        
        let output = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
        
        if !(effect ?? "").isEmpty {
            if String(effect) != "None" {
                
                let effectAttributed = ShapeDrawer.attributedCompose(effect, textattributes: ["font": PDFExporter.fontFamily, "size": "6.5", "weight": "Medium", "color": "black", "paragraphSpacingBefore": spacingBefore])
                let matches = Helpers.matchesWithRangesForRegexInAttributedText("(\\(.*\\))", text: effectAttributed)
                
                for match in matches {
                    if match.count > 1 {
                        for index in 1...match.count - 1 {
                            let (value, range) = match[index]
                            let replacement = ShapeDrawer.attributedCompose("\u{2029}" + value, textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "BookItalic", "color": "gray", "paragraphSpacingBefore": "0.6", "headIndent": "10.0", "firstLineHeadIndent": "10.0"])
                            effectAttributed.replaceCharactersInRange(range, withAttributedString: replacement)
                        }
                    }
                }
                
                output.appendAttributedString(effectAttributed)
                output.appendAttributedString(ShapeDrawer.attributedCompose("\u{2029}", textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Medium", "color": "black", "paragraphSpacingBefore": spacingBefore]))
            }
        }
        
        return output
        
    }
    
    
    static func generate(fileURL: NSURL, var rows: [[String: String]]) {
        
        
        // font family to be used
        
        let defaultFontFamily = Helpers.loadDefaults("prefsExportFontFamily")
        if !(defaultFontFamily ?? "").isEmpty {
            if ShapeDrawer.checkFontWeights(defaultFontFamily, weights: requiredFontWeights) {
                PDFExporter.fontFamily = defaultFontFamily
            }
            else {
                Helpers.runAlert("Font Family not Supported", text: "Font weight check: Some of the required weights are not supported by the chosen font. The default font will be used.")
            }
        }
        
        
        // user defined path containing the images
        
        let defaultImagesPath = Helpers.loadDefaults("prefsExportImagesPath")
        var imagesPath = ""
        if !(defaultImagesPath ?? "").isEmpty {
            imagesPath = defaultImagesPath
            // normalize the path
            if !imagesPath.hasSuffix("/") {
                imagesPath += "/"
            }
            if !imagesPath.hasPrefix("file://") {
                imagesPath = "file://" + imagesPath
            }
        }
        
        
        // page size
        
        let pgxsize = CGFloat(595.0)
        let pgysize = CGFloat(842.0)
        
        
        // card size
        
        var cardxsize = CGFloat(ShapeDrawer.mm2pt(63))
        var cardysize = CGFloat(ShapeDrawer.mm2pt(88))
        let cleancardxsize = cardxsize
        let cleancardysize = cardysize
        
        
        // image size
        
        var imagexsize = cardxsize
        var imageysize = CGFloat(ShapeDrawer.mm2pt(60))
        
        
        // card bleed
        
        let imageAssetsBleed = CGFloat(ShapeDrawer.mm2pt(2))
        var cardBleed = CGFloat(ShapeDrawer.mm2pt(0))
        let defaultCardBleed = Helpers.loadDefaults("prefsExportCardBleed")
        if (!(defaultCardBleed ?? "").isEmpty) {
            let NSDefaultCardBleed = defaultCardBleed as NSString
            cardBleed = CGFloat(ShapeDrawer.mm2pt(CGFloat(NSDefaultCardBleed.floatValue)))
            cardxsize += (cardBleed * CGFloat(2.0))
            cardysize += (cardBleed * CGFloat(2.0))
            imagexsize += (cardBleed * CGFloat(2.0))
            imageysize += (cardBleed * CGFloat(2.0))
        }
        
        
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
        
        let minpgxmargin = CGFloat(ShapeDrawer.mm2pt(2))
        let minpgymargin = CGFloat(ShapeDrawer.mm2pt(2))
        
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
                        ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound + cardBleed, yfrom: cardybound + cardBleed, xsize: cleancardxsize, ysize: cleancardysize)
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
                    let contentxbound = cardxbound + cardBleed
                    
                    var cardybound = CGFloat(cardysize * pgrow + pgymargin)
                    if (pgrow >= CGFloat(1)) {
                        cardybound += cardygutter * pgrow
                    }
                    let contentybound = cardybound + cardBleed
                    
                    let pagesIndexRise = (cardsperx * cardspery * CGFloat(pgnum))
                    let cardindex = pagesIndexRise + pgrow * cardsperx + pgcol + 1
                    
                    if (cardindex >= CGFloat(rows.count)) {
                        break
                    }
                    
                    
                    // simplify getting the current row
                    
                    let row = rows[Int(cardindex)]
                    
                    
                    // Draw a card image if found
                    
                    if !(row["Art File"] ?? "").isEmpty && !(imagesPath ?? "").isEmpty {
                        ShapeDrawer.safeDrawImageCropped(row["Art File"]!, directory: imagesPath, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: imagexsize, ysize: imageysize, cardxsize: cardxsize, cardysize: cardysize, cardBleed: cardBleed)
                    }
                    
                    
                    // draw backgrounds from asset catalog, set faction color
                    
                    var factionColor = "gray"
                    
                    if !(row["Faction"] ?? "").isEmpty {
                        switch String(row["Faction"]!) {
                        
                        case "Fascination":
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Fascination Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                            factionColor = "purple"
                            
                        case "Corruption":
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Corruption Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                            factionColor = "green"
                            
                        case "Violence":
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Violence Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                            factionColor = "red"
                            
                        case "Resonance":
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Resonance Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                            factionColor = "yellow"
                            
                        case "Machinery":
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Machinery Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                            factionColor = "blue"
                            
                        default:
                            ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Unaligned Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                        }
                    }
                    else {
                        ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Unaligned Base", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                    }
                    
                    if !(row["Power"] ?? "").isEmpty {
                        ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Myth Overlay", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                    }
                    
                    if !(row["Difficulty"] ?? "").isEmpty {
                        ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Scheme Overlay", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)
                    }
                    
                    
                    // include bleed marks
                    
                    if cardBleed > CGFloat(0.0) {
                        ShapeDrawer.drawImageFromAssetCatalogBleedClipped("Bleed Marks", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, assetBleed: imageAssetsBleed, targetBleed: cardBleed)

                    }

                    
                    // draw the card frame
                    
                    if printFrameAllPages {
                        ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    }
                    
                    
                    // typeset card name
                    
                    if (!(row["Name"] ?? "").isEmpty) {
                        frame = [CGFloat(24.0), CGFloat(9.5), CGFloat(138.0), CGFloat(30.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: row["Name"]!,
                            textattributes: ["font": PDFExporter.fontFamily, "size": "9", "weight": "Bold", "color": "white"]
                        )
                    }
                    
                    
                    // typeset card type, descent and class
                    
                    frame = [CGFloat(24.0), CGFloat(23.8), CGFloat(138.0), CGFloat(30.0)]
                    
                    let typeAndClasses = ShapeDrawer.attributedCompose("", textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Bold", "color": "black"])
                    
                    if (!(String(row["Playtype"]) ?? "").isEmpty) {
                        if (String(row["Playtype"]!) != "None" && !String(row["Playtype"]!).isEmpty) {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(String(row["Playtype"]!.uppercaseString) + " ", textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Bold", "color": factionColor]))
                        }
                    }
                    
                    if !(row["Type"] ?? "").isEmpty {
                        if String(row["Type"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(String(row["Type"]!.uppercaseString), textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Bold", "color": factionColor]))
                        }
                    }
                    
                    if !(row["Subtype"] ?? "").isEmpty {
                        if String(row["Subtype"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose("\u{2014}" + String(row["Subtype"]!.uppercaseString), textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Bold", "color": factionColor]))
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
                        typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" \u{2022}", textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Book", "color": factionColor]))
                    }
                    
                    if !(row["Descent"] ?? "").isEmpty {
                        if String(row["Descent"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" " + String(row["Descent"]!), textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Book", "color": factionColor]))
                        }
                    }
                    
                    if !(row["Class"] ?? "").isEmpty {
                        if String(row["Class"]!) != "None" {
                            typeAndClasses.appendAttributedString(ShapeDrawer.attributedCompose(" " + String(row["Class"]!), textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Book", "color": factionColor]))
                        }
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        typeAndClasses,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )
                    
                    
                    // typeset card text
                    
                    frame = [CGFloat(11.0), CGFloat(165.0), CGFloat(156.0), CGFloat(66.0)]
                    
                    let abilities = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
                    
                    if !(row["Ability 1 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 1 Cost"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Ability 1"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 1"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Ability 2 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 2 Cost"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Ability 2"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 2"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Ability 3 Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Ability 3 Cost"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Ability 3"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Ability 3"]!, spacingBefore: "3.0"))
                    }
                    if !(row["Achieved Ability"] ?? "").isEmpty {
                        if String(row["Achieved Ability"]!) != "None" {
                            abilities.appendAttributedString(ShapeDrawer.attributedCompose("ACHIEVED\u{000a}", textattributes: ["font": PDFExporter.fontFamily, "size": "5", "weight": "Medium", "color": "gray", "paragraphSpacingAfter": "0.5", "paragraphSpacingBefore": "3.0"]))
                        }
                    }
                    if !(row["Achieved Ability Cost"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatCost(row["Achieved Ability Cost"]!, spacingBefore: "0.0"))
                    }
                    if !(row["Achieved Ability"] ?? "").isEmpty {
                        abilities.appendAttributedString(self.preformatEffect(row["Achieved Ability"]!, spacingBefore: "0.0"))
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        abilities,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )
                    
                    
                    // typeset card claim
                    
                    frame = [CGFloat(9.45), CGFloat(10.5), CGFloat(16.0), CGFloat(140.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(row["Claim"]!, purpose: "generalMasking"),
                        textattributes: ["font": "FaithIcons", "size": "9.5", "color": "white", "lineSpacing": "1.5"] // do not include weight as the custom font apparently doesn't have one
                    )
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize(row["Claim"]!, purpose: "general"),
                        textattributes: ["font": "FaithIcons", "size": "9.5", "color": "black", "lineSpacing": "1.5"]
                    )

                    
                    // typeset scheme difficulty
                    
                    if !(row["Difficulty"] ?? "").isEmpty {
                        frame = [CGFloat(10.2), CGFloat(143.8), CGFloat(20.0), CGFloat(140.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: row["Difficulty"]!,
                            textattributes: ["font": PDFExporter.fontFamily, "size": "13", "weight": "Bold", "color": "white"]
                        )
                    }
                    
                    
                    // typeset myth/follower power
                    
                    if !(row["Power"] ?? "").isEmpty {
                        frame = [CGFloat(10.2), CGFloat(143.8), CGFloat(20.0), CGFloat(140.0)]
                        ShapeDrawer.drawShape(
                            "textframe",
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3],
                            text: row["Power"]!,
                            textattributes: ["font": PDFExporter.fontFamily, "size": "13", "weight": "Bold", "color": "white"]
                        )
                    }
                    
                    
                    // typeset lock icon
                    
                    frame = [CGFloat(11.0), CGFloat(240.5), CGFloat(16.0), CGFloat(140.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: ShapeDrawer.iconize("l", purpose: "general"),
                        textattributes: ["font": "FaithIcons", "size": "5", "color": "gray"]
                    )
                    
                    
                    // typeset meta
                    
                    frame = [CGFloat(17.0), CGFloat(241.0), CGFloat(138.0), CGFloat(70.0)]
                    let meta = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
                    let metaLineSpacing = "0.1"
                    
                    if !(copyrightNote ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(copyrightNote.uppercaseString, textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2005}\u{2022}\u{2005}", textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    meta.appendAttributedString(ShapeDrawer.attributedCompose(Helpers.getFormattedNow().uppercaseString, textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    
                    if !(row["Printing"] ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2005}\u{2022}\u{2005}", textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(row["Printing"]!.uppercaseString, textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    if !(row["Status"] ?? "").isEmpty {
                        meta.appendAttributedString(ShapeDrawer.attributedCompose("\u{2005}\u{2022}\u{2005}", textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                        meta.appendAttributedString(ShapeDrawer.attributedCompose(row["Status"]!.uppercaseString, textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "paragraphSpacingAfter": metaLineSpacing]))
                    }
                    
                    ShapeDrawer.drawAttributedString(
                        meta,
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3]
                    )

                    
                    // typeset credits
                    // TODO: incl. icon, ev. designer
                    
                    if !(row["Artist"] ?? "").isEmpty {
                        frame = [CGFloat(11.0), CGFloat(241.0), CGFloat(156.0), CGFloat(70.0)]
                        let credits = ShapeDrawer.attributedCompose("", textattributes: ["": ""])
                        credits.appendAttributedString(ShapeDrawer.attributedCompose("ART BY " + row["Artist"]!.uppercaseString, textattributes: ["font": PDFExporter.fontFamily, "size": "4", "weight": "Book", "color": "gray", "alignment": "right"]))

                        ShapeDrawer.drawAttributedString(
                            credits,
                            context: context!,
                            xfrom: ShapeDrawer.calculateXBound(contentxbound, baseSize: cleancardxsize, itemCoord: frame[0], itemSize: frame[2]),
                            yfrom: ShapeDrawer.calculateYBound(contentybound, baseSize: cleancardysize, itemCoord: frame[1], itemSize: frame[3]),
                            xsize: frame[2],
                            ysize: frame[3]
                        )
                    }
                    
                    
                } // pgrows
            } // pgcols
            
            CGPDFContextEndPage(context)
            
        } // pages
        
        CGPDFContextClose(context)
    
    }
    
}
