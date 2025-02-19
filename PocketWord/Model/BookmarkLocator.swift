//
//  BookmarkLocator.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//

import Foundation
import Defaults

struct RangeLocator: Hashable, Codable, Defaults.Serializable {
    let version: BibleVersion
    let book: Int
    let chapter: Int
    let range: NSRange
}


struct TitleDisplay: Hashable {
    var book: String = ""
    var chapter: String = ""
}
