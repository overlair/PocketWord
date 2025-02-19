//
//  BibleVersion.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//

import Foundation
import GRDB
import Defaults

enum BibleVersion: Int, Hashable, Codable, CaseIterable, DatabaseValueConvertible, Defaults.Serializable {
    case kjv
}


// add label
// add attribute for if isDownloadable
// add identifier for remote store/local file
