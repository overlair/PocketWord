//
//  Defaults+.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import SwiftUI
import Defaults


extension Defaults.Keys {
    static let version = Defaults.Key<BibleVersion>("version", default: .kjv)
    static let book = Defaults.Key<Int>("book", default: 1)
    static let chapter = Defaults.Key<Int>("chapter", default: 1)
    
    
    static let highlight = Defaults.Key<HighlightColor>("highlight", default: .yellow)
    static let bookmark = Defaults.Key<RangeLocator?>("bookmark", default: nil)
    
    static let textSize = Defaults.Key<CGFloat>("textSize", default: 1)
    static let lineSpacing = Defaults.Key<CGFloat>("lineSpacing", default: 1)
    static let pageColor = Defaults.Key<Color>("pageColor", default: .clear)

}

