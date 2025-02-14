//
//  NSAttributedString+.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import Foundation


extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect,
                                       options: .usesLineFragmentOrigin,
                                       context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude,
                                    height: height)
        let boundingBox = boundingRect(with: constraintRect,
                                       options: .usesLineFragmentOrigin,
                                       context: nil)
        
        return ceil(boundingBox.width)
    }
}





extension NSAttributedString.Key {
    static let verseNumber: NSAttributedString.Key = .init("verseNumber")
    static let verse: NSAttributedString.Key = .init("verse")
    static let bookmark: NSAttributedString.Key = .init("bookmark")
    static let highlight: NSAttributedString.Key = .init("highlight")
}




extension String {
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
              let range = self.range(of: string, options: [.caseInsensitive, .regularExpression], range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
}
