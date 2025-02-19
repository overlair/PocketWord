//
//  HighlightColor.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//

import GRDB
import SwiftUI
import Defaults

enum HighlightColor: Int, Hashable, Codable, CaseIterable, DatabaseValueConvertible, Defaults.Serializable {
    case yellow
    case orange
    case green
    case pink
    case purple
}

extension HighlightColor {
    var uiColor: UIColor { UIColor(color) }
    
    var color: Color {
        switch self {
        case .yellow: .yellow
        case .orange: .orange
        case .green: .green
        case .pink: .pink
        case .purple: .purple
        }
    }
}
