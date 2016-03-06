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
    
    
    static func checkFontWeights(fontFamily: String, weights: [[String]]) -> Bool {
        for weight in weights{
            var altWeightFound = false
            for altWeight in weight {
                let font = NSFont(name: fontFamily + "-" + altWeight, size: 10.0)
                if font != nil {
                    altWeightFound = true
                }
            }
            if !altWeightFound {
                return false
            }
        }
        return true
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
            CGContextSetStrokeColorWithColor(context, NSColor.blackColor().CGColor)
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextStrokePath(context)
            
            
        case "fillrect":
            CGContextAddRect(context, CGRectMake(xfrom, yfrom, xsize, ysize))
            CGContextSetRGBFillColor (context, 1, 0, 0, 1)
            CGContextFillPath(context)
            
            
        case "textframe":
            var font = NSFont(name: "Lato-Regular", size: 10.0)
            
            if (textattributes["font"] != nil && font != nil) {
                textattributes["font"]
                font = NSFont(name: textattributes["font"]!, size: 10.0)
            }
            
            if (textattributes["weight"] != nil && font != nil) {
                let fontNameWithWeight = font!.fontName.componentsSeparatedByString("-").first! + "-" + textattributes["weight"]!
                font = NSFont(name: fontNameWithWeight, size: 10.0)
            }
            
            if (textattributes["size"] != nil && font != nil) {
                let customsize = textattributes["size"]! as NSString
                font = NSFont(name: font!.fontName, size: CGFloat(customsize.floatValue))
            }
            
            let paragraphStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            
            var textColor = NSColor.blackColor()
            if (textattributes["color"] != nil) {
                textColor = parseColor(textattributes["color"]!)
            }
            
            if (textattributes["lineSpacing"] != nil) {
                let lineSpacing = textattributes["lineSpacing"]! as NSString
                paragraphStyle.lineSpacing = CGFloat(lineSpacing.floatValue)
            }
            
            if (textattributes["paragraphSpacingAfter"] != nil) {
                let paragraphSpacingAfter = textattributes["paragraphSpacingAfter"]! as NSString
                paragraphStyle.paragraphSpacing = CGFloat(paragraphSpacingAfter.floatValue)
            }
            
            if (textattributes["paragraphSpacingBefore"] != nil) {
                let paragraphSpacingBefore = textattributes["paragraphSpacingBefore"]! as NSString
                paragraphStyle.paragraphSpacingBefore = CGFloat(paragraphSpacingBefore.floatValue)
            }
            
            
            if (font != nil) {
                let textFontAttributes = [
                    NSFontAttributeName : font!,
                    NSForegroundColorAttributeName: textColor,
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
                
                CGContextSetTextMatrix(context, CGAffineTransformIdentity)
                
                let attributedString = NSMutableAttributedString(string: text, attributes: textFontAttributes)
                
                self.drawAttributedString(attributedString, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize)
            }
            
            
        default:
            break
        }
        
    }
    
    
    static func drawAttributedString(text: NSMutableAttributedString, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        self.drawAttributedString(text, context: context, xfrom: xfrom, yfrom: yfrom, xsize: xsize, ysize: ysize, paragraphAttributes: ["": ""])
    }
    
    static func drawAttributedString(text: NSMutableAttributedString, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, paragraphAttributes: [String: String]) {
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity)
        
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        
        if (paragraphAttributes["paragraphSpacingAfter"] != nil) {
            let range = NSRange(location: 0, length: text.length)
            let paragraphSpacingAfter = paragraphAttributes["paragraphSpacingAfter"]! as NSString
            textStyle.paragraphSpacing = CGFloat(paragraphSpacingAfter.floatValue)
            text.addAttribute("NSParagraphStyle", value: textStyle, range: range)
        }
        
        let framesetter =  CTFramesetterCreateWithAttributedString(text);
        let path = CGPathCreateWithRect(CGRectMake(xfrom, yfrom, xsize, ysize), nil);
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil);
        CTFrameDraw(frame, context);
    
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
    
    
    static func safeDrawImageCropped(filename: String, directory: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, cardxsize: CGFloat, cardysize: CGFloat, cardBleed: CGFloat) {
    
        // try all the formats
        for format in PDFExporter.imageFormatExtensions {
            
            let escPath = (directory + filename + format).stringByReplacingOccurrencesOfString(" ", withString: "%20")
            let filePath = NSURL(string: escPath)
            let imageSource = CGImageSourceCreateWithURL(filePath! as CFURL, nil)
            if imageSource != nil {
                var image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
                
                // crop it, remember bleed
                let imageXSize = CGFloat(CGImageGetWidth(image))
                let imageYSize = CGFloat(CGImageGetHeight(image))
                let originalRatio = imageXSize / imageYSize
                let targetRatio = xsize / ysize
                
                if originalRatio > targetRatio {
                    let targetXSize = imageYSize * targetRatio
                    let cutXFrom = (imageXSize - targetXSize) / 2
                    let area = CGRectMake(cutXFrom, CGFloat(0.0), targetXSize, imageYSize)
                    image = CGImageCreateWithImageInRect(image, area)
                }
                else {
                    let targetYSize = imageXSize * targetRatio
                    let cutYFrom = (imageYSize - targetYSize) / 3 // crop origin shift from center
                    let area = CGRectMake(CGFloat(0.0), cutYFrom, imageXSize, targetYSize)
                    image = CGImageCreateWithImageInRect(image, area)
                }
                
                // draw it
                let area = CGRectMake(xfrom, yfrom + (cardysize - ysize), xsize, ysize)
                CGContextDrawImage(context, area, image)

                break
            }
        }
    
    }

    
    static func drawImageFromAssetCatalog(imageName: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat) {
        
        let image = NSImage(named: imageName)?.CGImageForProposedRect(nil, context: nil, hints: nil)
        CGContextDrawImage(context, CGRectMake(xfrom, yfrom, xsize, ysize), image);
    
    }
    
    
    static func drawImageFromAssetCatalogBleedClipped(imageName: String, context: CGContextRef, xfrom: CGFloat, yfrom: CGFloat, xsize: CGFloat, ysize: CGFloat, assetBleed: CGFloat, targetBleed: CGFloat) {
        
        let image = NSImage(named: imageName)?.CGImageForProposedRect(nil, context: nil, hints: nil)
        var subImage = image
        if assetBleed > targetBleed {
            let imageXSize = CGFloat(CGImageGetWidth(image))
            let imageYSize = CGFloat(CGImageGetHeight(image))
            
            let ratio = imageXSize / (xsize - targetBleed + assetBleed)
            let bleedCut = (assetBleed - targetBleed) * ratio
            
            let area = CGRectMake(bleedCut, bleedCut, imageXSize - (CGFloat(2.0) * bleedCut), imageYSize - (CGFloat(2.0) * bleedCut))
            subImage = CGImageCreateWithImageInRect(image, area)
        }
        CGContextDrawImage(context, CGRectMake(xfrom, yfrom, xsize, ysize), subImage)
        
    }


    static func iconize(string: String) -> String {
        return self.iconize(string, purpose: "general")
    }
    
    static func iconize(string: String, purpose: String) -> String {
        
        var output = string.lowercaseString
        
        let icons: NSMutableDictionary = [
            "l": "\u{e919}",
            "p": "\u{e91a}"
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
                
                "*": "\u{e945}",
                "×": "\u{e946}",
                "x": "\u{e946}",
                
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
                
                "c": "\u{e90f}",
                "f": "\u{e910}",
                "m": "\u{e911}",
                "r": "\u{e912}",
                "v": "\u{e913}",
                
                "*": "\u{e943}",
                "×": "\u{e944}",
                "x": "\u{e944}",
                
                "i": "\u{e915}"
            ])
            
        case "power":
            icons.addEntriesFromDictionary([
                "0": "\u{e937}",
                "1": "\u{e938}",
                "2": "\u{e939}",
                "3": "\u{e93a}",
                "4": "\u{e93b}",
                "5": "\u{e93c}",
                "6": "\u{e93d}",
                "7": "\u{e93e}",
                "8": "\u{e93f}",
                "9": "\u{e940}",
                
                "c": "\u{e932}",
                "f": "\u{e933}",
                "m": "\u{e934}",
                "r": "\u{e935}",
                "v": "\u{e936}",
                
                "*": "\u{e941}",
                "×": "\u{e942}",
                "x": "\u{e942}",
                
                "i": "\u{e933}"
            ])
            
        default:
            icons.addEntriesFromDictionary([
                "0": "\u{e900}",
                "1": "\u{e901}",
                "2": "\u{e902}",
                "3": "\u{e903}",
                "4": "\u{e904}",
                "5": "\u{e905}",
                "6": "\u{e906}",
                "7": "\u{e907}",
                "8": "\u{e908}",
                "9": "\u{e909}",
                
                "c": "\u{e90a}",
                "f": "\u{e90b}",
                "m": "\u{e90c}",
                "r": "\u{e90d}",
                "v": "\u{e90e}",
                
                "*": "\u{e947}",
                "×": "\u{e948}",
                "x": "\u{e948}",
                
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
            
        case "powerMasking":
            output = maskIcons(output, mask: "\u{e949}")

        default:
            for (key, value) in icons {
                output = output.stringByReplacingOccurrencesOfString(key as! String, withString: value as! String)
            }
        
        }

        return output

    }
    
    
    // changes font of the provided string to FaithIcons, returns NSAttributedString object
    
    static func attributedCompose(inputString: String, textattributes: [String: String]) -> NSMutableAttributedString {
        
        var attributes: [String: AnyObject] = [NSFontAttributeName: NSNull()]
        
        if !(textattributes["font"] ?? "").isEmpty {
            attributes[NSFontAttributeName] = NSFont(name: textattributes["font"]!, size: 10.0)
        }
        
        if !(textattributes["weight"] ?? "").isEmpty {
            let fontNameWithWeight = attributes[NSFontAttributeName]!.fontName.componentsSeparatedByString("-").first! + "-" + textattributes["weight"]!
            attributes[NSFontAttributeName] = NSFont(name: fontNameWithWeight, size: 10.0)
        }
        
        if !(textattributes["size"] ?? "").isEmpty {
            let size = textattributes["size"]! as NSString
            attributes[NSFontAttributeName] = NSFont(name: attributes[NSFontAttributeName]!.fontName, size: CGFloat(size.floatValue))
        }
        
        if !(textattributes["kerning"] ?? "").isEmpty {
            let kerning = textattributes["kerning"]! as NSString
            attributes[NSKernAttributeName] = CGFloat(kerning.floatValue)
        }
        
        let paragraphStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        
        if !(textattributes["tailIndent"] ?? "").isEmpty {
            let tailIndent = textattributes["tailIndent"]! as NSString
            paragraphStyle.tailIndent = CGFloat(tailIndent.floatValue)
        }
        
        if !(textattributes["headIndent"] ?? "").isEmpty {
            let headIndent = textattributes["headIndent"]! as NSString
            paragraphStyle.headIndent = CGFloat(headIndent.floatValue)
        }
        
        if !(textattributes["firstLineHeadIndent"] ?? "").isEmpty {
            let firstLineHeadIndent = textattributes["firstLineHeadIndent"]! as NSString
            paragraphStyle.firstLineHeadIndent = CGFloat(firstLineHeadIndent.floatValue)
        }
        
        if !(textattributes["lineSpacing"] ?? "").isEmpty {
            let lineSpacing = textattributes["lineSpacing"]! as NSString
            paragraphStyle.lineSpacing = CGFloat(lineSpacing.floatValue)
        }
        
        if !(textattributes["alignment"] ?? "").isEmpty {
            var alignment = NSTextAlignment.Left
            switch textattributes["alignment"]! {
            case "center":
                alignment = NSTextAlignment.Center
            case "left":
                alignment = NSTextAlignment.Left
            case "right":
                alignment = NSTextAlignment.Right
            case "justified":
                alignment = NSTextAlignment.Justified
            case "natural":
                alignment = NSTextAlignment.Natural
            default:
                break
            }
            paragraphStyle.alignment = alignment
        }
        
        if !(textattributes["paragraphSpacingAfter"] ?? "").isEmpty {
            let paragraphSpacingAfter = textattributes["paragraphSpacingAfter"]! as NSString
            paragraphStyle.paragraphSpacing = CGFloat(paragraphSpacingAfter.floatValue)
        }
        
        if !(textattributes["paragraphSpacingBefore"] ?? "").isEmpty {
            let paragraphSpacingBefore = textattributes["paragraphSpacingBefore"]! as NSString
            paragraphStyle.paragraphSpacingBefore = CGFloat(paragraphSpacingBefore.floatValue)
        }

        attributes[NSForegroundColorAttributeName] = NSColor.blackColor()
        if !(textattributes["color"] ?? "").isEmpty {
            attributes[NSForegroundColorAttributeName] = parseColor(textattributes["color"]!)
        }
        
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        
        return NSMutableAttributedString(string: "\(inputString)", attributes: attributes)
    }
    
    
    static func parseColor(color: String) -> NSColor {
        
        switch color {
            
        case "red":
            return NSColor(r: 206, g: 57, b: 57, a: 255)
        case "purple":
            return NSColor(r: 169, g: 62, b: 131, a: 255)
        case "blue":
            return NSColor(r: 31, g: 114, b: 169, a: 255)
        case "green":
            return NSColor(r: 37, g: 143, b: 110, a: 255)
        case "yellow":
            return NSColor(r: 219, g: 168, b: 25, a: 255)
            
        case "black":
            return NSColor.blackColor()
        case "white":
            return NSColor.whiteColor()
        case "gray":
            return NSColor(r: 100, g: 116, b: 137, a: 255)
        case "grey":
            return NSColor(r: 100, g: 116, b: 137, a: 255)
        default:
            return NSColor.blackColor()
        }
        
    }
    
    
}