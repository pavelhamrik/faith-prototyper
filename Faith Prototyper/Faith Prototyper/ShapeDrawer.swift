//
//  ShapeDrawer.swift
//  Faith Prototyper
//
//  Created by Pavel Hamřík on 18.12.15.
//  Copyright © 2015 Pavel Hamřík. All rights reserved.
//

import Cocoa

class ShapeDrawer {
    
    
    static func maskIcons(string: String, mask: String) -> String {
        let iconsCount = string.characters.count
        var output = ""
        for var count = 0; count < iconsCount; count += 1 {
            output += mask
        }
        return output
    }

    
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
            
            var textColor = NSColor.blackColor()
            if (textattributes["color"] != nil) {
                let color = textattributes["color"]!
                switch color {
                case "black":
                    textColor = NSColor.blackColor()
                case "white":
                    textColor = NSColor.whiteColor()
                case "red":
                    textColor = NSColor.redColor()
                case "gray":
                    textColor = NSColor.grayColor()
                default:
                    textColor = NSColor.blackColor()
                }
            }
            
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


    static func iconize(string: String) -> String {
        return self.iconize(string, purpose: "general")
    }
    
    static func iconize(string: String, purpose: String) -> String {
        
        var output = string.lowercaseString
        
        let icons: NSMutableDictionary = [
            "circle": "\u{e91b}",
            "diamond": "\u{e91c}",
            "pentagon": "\u{e91d}",
            "lock": "\u{e919}",
            "pencil": "\u{e91a}"
        ]
        
        switch purpose {
            
        case "belief":
            icons.addEntriesFromDictionary([
                "0": "\u{e928}",
                "1": "\u{e929}",
                "2": "\u{e92a}",
                "3": "\u{e92b}",
                "4": "\u{e92c}",
                "5": "\u{e92d}",
                "6": "\u{e92e}",
                "7": "\u{e92f}",
                "8": "\u{e930}",
                "9": "\u{e931}",
                
                "c": "\u{e914}",
                "f": "\u{e915}",
                "m": "\u{e916}",
                "r": "\u{e917}",
                "v": "\u{e918}",
                
                "i": "\u{e915}",
            ])
            
        case "difficulty":
            icons.addEntriesFromDictionary([
                "0": "\u{e91e}",
                "1": "\u{e91f}",
                "2": "\u{e920}",
                "3": "\u{e921}",
                "4": "\u{e922}",
                "5": "\u{e923}",
                "6": "\u{e924}",
                "7": "\u{e925}",
                "8": "\u{e926}",
                "9": "\u{e927}",
                
                "c": "\u{e914}",
                "f": "\u{e915}",
                "m": "\u{e916}",
                "r": "\u{e917}",
                "v": "\u{e918}",
                
                "i": "\u{e915}"
            ])
            
        default:
            icons.addEntriesFromDictionary([
                "0": "\u{e900}",
                "1": "\u{e901}",
                "2": "\u{e901}",
                "3": "\u{e901}",
                "4": "\u{e901}",
                "5": "\u{e901}",
                "6": "\u{e901}",
                "7": "\u{e901}",
                "8": "\u{e901}",
                "9": "\u{e901}",
                
                "c": "\u{e90a}",
                "f": "\u{e90b}",
                "m": "\u{e90c}",
                "r": "\u{e90d}",
                "v": "\u{e90e}",
                
                "i": "\u{e90b}"
                ])
        }
        
        
        switch purpose {
        
        case "generalMasking":
            output = maskIcons(output, mask: "\u{e91b}")
            
        case "beliefMasking":
            output = maskIcons(output, mask: "\u{e91d}")
            
        case "difficultyMasking":
            output = maskIcons(output, mask: "\u{e91c}")

        default:
            for (key, value) in icons {
                output = output.stringByReplacingOccurrencesOfString(key as! String, withString: value as! String)
            }
        
        }

        return output

    }
    
    
    static func attributedCompose (inputString: String) -> NSAttributedString {
        // changes font of the provided string to FaithIcons, returns NSAttributedString object
        
        var attributes: [String: AnyObject] = [NSFontAttributeName: NSNull()]
        attributes[NSFontAttributeName] = NSFont(name: "FaithIcons", size: 12.0)
        // Don't forget to adjust size
        
        return NSAttributedString(string: "\(inputString)", attributes: attributes)
    }
    
    
}