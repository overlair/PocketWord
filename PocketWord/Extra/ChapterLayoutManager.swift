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
        print("draw glyphs")
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage?.enumerateAttribute(.bookmark, in: characterRange, using: { (value, subrange, _) in
            guard let color = value as? UIColor else { return }
            let tokenGlypeRange = glyphRange(forCharacterRange: subrange, actualCharacterRange: nil)
            drawToken(forGlyphRange: tokenGlypeRange, color: color)
        })
        textStorage?.enumerateAttribute(.highlight, in: characterRange, using: { (value, subrange, _) in
            guard let color = value as? UIColor else { return }
            let tokenGlypeRange = glyphRange(forCharacterRange: subrange, actualCharacterRange: nil)
            drawToken(forGlyphRange: tokenGlypeRange, color: color)
        })
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
     
    private func drawToken(forGlyphRange tokenGlypeRange: NSRange, color: UIColor = UIColor(hue: 175.0/360.0, saturation: 0.24, brightness: 0.88, alpha: 1)) {
        print("draw tokens")
        guard let textContainer = textContainer(forGlyphAt: tokenGlypeRange.location, effectiveRange: nil) else { return }
        let withinRange = NSRange(location: NSNotFound, length: 0)
        enumerateEnclosingRects(forGlyphRange: tokenGlypeRange, withinSelectedGlyphRange: withinRange, in: textContainer) { (rect, _) in
            let tokenRect = rect.offsetBy(dx: self.textContainerOriginOffset.width, dy: self.textContainerOriginOffset.height)
            color.setFill()
            UIBezierPath(rect: tokenRect).fill()
        }
    }
}
