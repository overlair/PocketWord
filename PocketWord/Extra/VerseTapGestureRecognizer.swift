//
//  VerseTapGestureRecognizer.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import UIKit

class  VerseTapGestureRecognizer: UITapGestureRecognizer {
    typealias TappedVerse = (range: NSRange, verse: Int)

    private(set) var tappedState: TappedVerse?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        tappedState = nil
        
        guard let textView = view as? UITextView else {
            state = .failed
            return
        }
        
        if let touch = touches.first {
            tappedState = evaluateTouch(touch, on: textView)
        }
        
        if tappedState != nil {
            // UITapGestureRecognizer can accurately differentiate discrete taps from scrolling
            // Therefore, let the super view evaluate the correct state.
            super.touchesBegan(touches, with: event)
            
        } else {
            // User didn't initiate a touch (tap or otherwise) on an attachment.
            // Force the gesture to fail.
            state = .failed
        }
    }
    
    /// Tests to see if the user has tapped on a text attachment in the target text view.
    private func evaluateTouch(_ touch: UITouch, on textView: UITextView) -> TappedVerse? {
        let touch = touch.location(in: textView)
        let point = CGPoint(x: touch.x - textView.textContainerInset.left,
                            y: touch.y - textView.textContainerInset.top)
        let position = textView.closestPosition(to: point) ?? textView.beginningOfDocument
        let offset = textView.offset(from: textView.beginningOfDocument, to: position)
        let length = textView.offset(from: textView.beginningOfDocument, to: textView.endOfDocument)
        let verse = textView.textStorage.attribute(.verse, at: offset, effectiveRange: nil) as? Int
        let range = NSRange(location: 0, length: length)
        var foundVerse = TappedVerse?.none
        textView.textStorage.enumerateAttribute(.verse, in: range) {  value, range, shouldContinue in
            if let v = value as? Int, v == verse {
                foundVerse = TappedVerse(range, v)
                shouldContinue.pointee = false
            }
        }
        
        return foundVerse
    }
}
