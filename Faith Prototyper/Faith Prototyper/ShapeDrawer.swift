//
//  ShapeDrawer.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ShapeDrawer {
    
    static func mm2pt(mm: CGFloat) -> CGFloat {
        let ratio = 2.8333
        return CGFloat(mm * CGFloat(ratio))
    }
    
    
    static func calculateXBound(baseCoord: CGFloat, baseSize: CGFloat, itemCoord: CGFloat, itemSize: CGFloat) -> CGFloat {
        return baseCoord + itemCoord
    }
    
    static func calculateYBound(baseCoord: CGFloat, baseSize: CGFloat, itemCoord: CGFloat, itemSize: CGFloat) -> CGFloat {
        return baseCoord + baseSize - (itemCoord + itemSize)
    }
    
    
    static func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        self.drawShape(shape, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, text: "", textattributes: ["": ""])
    }
    
    static func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, text: String) {
        self.drawShape(shape, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, text: text, textattributes: ["": ""])
    }
    
    static func drawShape(shape: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, text: String, textattributes: [String: String]) {
        let thinline = CGFloat(0.25)
        // colors as params; params as array/dictionary?
        
        switch shape {
            
        case "linerect":
            CGContextSetLineWidth(context, thinline)
            CGContextSetStrokeColorWithColor(context, NSColor.redColor().CGColor)
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextStrokePath(context)
            
            
        case "fillrect":
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextSetRGBFillColor (context, 1, 0, 0, 1)
            CGContextFillPath(context)
            
            
        case "textframe":
            var font = NSFont(name: "Lato", size: 10.0)
            if (textattributes["font"] != nil) {
                font = NSFont(name: textattributes["font"]!, size: 10.0)
            }
            if (textattributes["weight"] != nil) {
                let fontNameWithWeight = font!.fontName.componentsSeparatedByString("-").first! + "-" + textattributes["weight"]!
                font = NSFont(name: fontNameWithWeight, size: 10.0)
            }
            if (textattributes["size"] != nil) {
                let customsize = textattributes["size"]! as NSString
                font = NSFont(name: font!.fontName, size: CGFloat(customsize.intValue))
            }
            
            let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            let textColor = NSColor.blackColor()
            
            if (textattributes["lineSpacing"] != nil) {
                let lineSpacing = textattributes["lineSpacing"]! as NSString
                textStyle.lineSpacing = CGFloat(lineSpacing.intValue)
            }
            
            let textFontAttributes = [
                NSFontAttributeName : font!,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: textStyle
            ]
            
            CGContextSetTextMatrix(context, CGAffineTransformIdentity)
            
            let attributedString = NSMutableAttributedString(string: text, attributes: textFontAttributes)
            
            let framesetter =  CTFramesetterCreateWithAttributedString(attributedString);
            let path = CGPathCreateWithRect(CGRectMake(xfrom, yfrom, xsize, ysize), nil);
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
            CTFrameDraw(frame, context);
            
        default:
            break
        }
        
    }
    
    
    static func drawImageFromURL(imageURL: NSURL, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        self.drawImageFromURL(imageURL, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, attributes: ["": ""])
    }
    
    static func drawImageFromURL(imageURL: NSURL, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, attributes: [String: String]) {
        
        let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        self.drawImageFromSource(imageSource!, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize)
        
    }
    
    
    static func drawImageFromSource(imageSource: CGImageSource, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        self.drawImageFromSource(imageSource, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, attributes: ["": ""])
    }
    
    static func drawImageFromSource(imageSource: CGImageSource, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, attributes: [String: String]) {
        
        // handle parameters?
        
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        CGContextDrawImage(context, CGRectMake(xfrom, yfrom, xsize, ysize), image);
        
    }


}