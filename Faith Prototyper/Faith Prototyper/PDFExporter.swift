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
                    
                    ShapeDrawer.drawShape("linerect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    
                    if (pgrow == CGFloat(0) && pgcol == CGFloat(0)) {
                        ShapeDrawer.drawShape("fillrect", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    }
                    
                    let textAttributes = ["font": "Lato", "size": "18", "weight": "Light", "color": "black"]
                    ShapeDrawer.drawShape("textframe", context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize, text: rows[Int(cardindex)]["Name"] as! String, textattributes: textAttributes)
                    
                    // draw backgrounds from previously downloaded CFImageSource
                    ShapeDrawer.drawImageFromSource(cardBackSource!, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)

                    
                    //ShapeDrawer.drawImageFromURL(NSURL(string: "file:///Users/pavelhamrik/Dropbox/Public/faith/mac/background_Grey.png")!, context: context!, xfrom: cardxbound, yfrom: cardybound, xsize: cardxsize, ysize: cardysize)
                    
                    
                } // pgrows
            } // pgcols
            
            CGPDFContextEndPage(context)
            
        } // pages
        
        CGPDFContextClose(context)
    
    }
    
}



