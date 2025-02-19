//
//  ChapterLayoutManager.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import UIKit

final class ChapterLayoutManager: NSLayoutManager {
    var textContainerOriginOffset: CGSize = .zero
     
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage?.enumerateAttribute(.bookmark, in: characterRange, using: { (value, subrange, _) in
            guard let color = value as? UIColor else { return }
            let tokenGlypeRange = glyphRange(forCharacterRange: subrange, actualCharacterRange: nil)
            drawBookmark(forGlyphRange: tokenGlypeRange, color: color)
        })
        textStorage?.enumerateAttribute(.highlight, in: characterRange, using: { (value, subrange, _) in
            guard let color = value as? UIColor else { return }
            let tokenGlypeRange = glyphRange(forCharacterRange: subrange, actualCharacterRange: nil)
            drawHighlight(forGlyphRange: tokenGlypeRange, color: color)
        })
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
     
    private func drawHighlight(forGlyphRange tokenGlypeRange: NSRange, color: UIColor = UIColor(hue: 175.0/360.0, saturation: 0.24, brightness: 0.88, alpha: 1)) {
        guard let textContainer = textContainer(forGlyphAt: tokenGlypeRange.location, effectiveRange: nil) else { return }
        let withinRange = NSRange(location: NSNotFound, length: 0)
        enumerateEnclosingRects(forGlyphRange: tokenGlypeRange, withinSelectedGlyphRange: withinRange, in: textContainer) { (rect, _) in
            let tokenRect = rect.offsetBy(dx: self.textContainerOriginOffset.width, dy: self.textContainerOriginOffset.height)
            color.setFill()
            UIBezierPath(rect: tokenRect).fill()
        }
    }
    
    private func drawBookmark(forGlyphRange tokenGlypeRange: NSRange, color: UIColor = UIColor(hue: 175.0/360.0, saturation: 0.24, brightness: 0.88, alpha: 1)) {
        guard let textContainer = textContainer(forGlyphAt: tokenGlypeRange.location, effectiveRange: nil) else { return }
        let withinRange = NSRange(location: NSNotFound, length: 0)
        var rects = [CGRect]()
        enumerateEnclosingRects(forGlyphRange: tokenGlypeRange, withinSelectedGlyphRange: withinRange, in: textContainer) { (rect, _) in
            let tokenRect = rect.offsetBy(dx: self.textContainerOriginOffset.width, dy: self.textContainerOriginOffset.height)
            let rect = CGRect(origin: .init(x: textContainer.size.width + 19, y: tokenRect.minY),
                              size: .init(width: 4, height: tokenRect.height))
            rects.append(rect)
        }
        
        color.setFill()
        
        if rects.count == 1 {
            UIBezierPath(roundedRect: rects[0], cornerRadius: 2).fill()
        } else {
            for rect in rects {
                if rect == rects.first {
                    UIBezierPath(roundedRect: rect,
                                 byRoundingCorners: [.topLeft, .topRight],
                                 cornerRadii: .init(width: 2, height: 2)).fill()

                } else if rect == rects.last {
                    UIBezierPath(roundedRect: rect,
                                 byRoundingCorners: [.bottomLeft, .bottomRight],
                                 cornerRadii: .init(width: 2, height: 2)).fill()
                } else {
                    UIBezierPath(rect: rect).fill()
                }
            }
            
        }
    }

}
