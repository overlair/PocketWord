//
//  UIImage+.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import UIKit

extension UIImage {
    public func tinted(_ color: UIColor) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
