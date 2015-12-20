//
//  PDFExporter.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class PDFExporter {
    
    static func generate(fileURL: NSURL, rows: [NSMutableDictionary]) {
        
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
        
        
        let pgnums = Int(ceil(CGFloat(rows.count) / (cardsperx * cardspery)))
        for var pgnum = 0; pgnum < pgnums; pgnum += 1 {
            
            CGPDFContextBeginPage(context, nil)
            
            for var pgrow = CGFloat(0.0); pgrow < cardsperx; pgrow += 1 {
                for var pgcol = CGFloat(0.0); pgcol < cardspery; pgcol += 1 {
                    
                    var frame = [CGFloat(0.0), CGFloat(0.0), CGFloat(50.0), CGFloat(10.0)]
                    
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
                    frame = [CGFloat(31.5), CGFloat(11.5), CGFloat(138.0), CGFloat(30.0)]
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
                    
                    // typeset card type
                    // TODO: classes, attributed string, bullet as connector, font weights for classes
                    frame = [CGFloat(31.5), CGFloat(22.5), CGFloat(138.0), CGFloat(30.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: rows[Int(cardindex)]["Type"] as! String,
                        textattributes: ["font": "Lato", "size": "7", "weight": "Heavy", "color": "black"]
                    )
                    
                    // typeset text
                    // TODO: attributed string, icons, etc.
                    frame = [CGFloat(31.5), CGFloat(137.5), CGFloat(138.0), CGFloat(70.0)]
                    ShapeDrawer.drawShape(
                        "textframe",
                        context: context!,
                        xfrom: ShapeDrawer.calculateXBound(cardxbound, baseSize: cardxsize, itemCoord: frame[0], itemSize: frame[2]),
                        yfrom: ShapeDrawer.calculateYBound(cardybound, baseSize: cardysize, itemCoord: frame[1], itemSize: frame[3]),
                        xsize: frame[2],
                        ysize: frame[3],
                        text: rows[Int(cardindex)]["Text"] as! String,
                        textattributes: ["font": "Lato", "size": "7", "weight": "Regular", "color": "black"]
                    )
                    
                    

                    
                    
                    
                } // pgrows
            } // pgcols
            
            CGPDFContextEndPage(context)
            
        } // pages
        
        CGPDFContextClose(context)
    
    }
    
}



