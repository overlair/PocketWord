//
//  Constant.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import SwiftUI



enum Constant {
//    static let textBaseFont = UIFont.systemFont(ofSize: <#T##CGFloat#>, weight: <#T##UIFont.Weight#>)
    
    static let navBarConfig = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17, weight: .bold)).applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel))
    static let selectBarConfig = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 27, weight: .bold))
    static let selectBarBigConfig = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 33, weight: .bold))

    static func bodyFont() -> UIFont {
        let fontSize = CGFloat(19)

        guard let customFont = UIFont(name: "Merriweather-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        
        return customFont
    }
      
    static func noteFont() -> UIFont {
        let fontSize = CGFloat(19)

        guard let vFont = VFont(name: "MerriweatherSans-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        
        vFont.setValue(600, forAxisID: 2003265652)

        return vFont.uiFont
    }
    
    static func bookFont() -> UIFont {
        let fontSize = CGFloat(37)
        
        guard let vFont = VFont(name: "CrimsonPro-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        
        vFont.setValue(800, forAxisID: 2003265652)
        return vFont.uiFont
            
    }
    
    static func titleBookFont() -> UIFont {
        let fontSize = CGFloat(25)
        
        guard let vFont = VFont(name: "CrimsonPro-Regular", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        
        vFont.setValue(900, forAxisID: 2003265652)
        return vFont.uiFont
            
    }
    
    static func chapterFont() -> UIFont {
        let fontSize = CGFloat(45)

        guard let customFont = UIFont(name: "Merriweather-Bold", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        
        return customFont
    }
    
    static func labelFont(size: CGFloat = 25) -> UIFont {
        guard let vFont = VFont(name: "MerriweatherSans-Regular", size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        
        vFont.setValue(500, forAxisID: 2003265652)

        return vFont.uiFont
    }
    
    static let chapterInset = UIEdgeInsets(top: 13, left: 11, bottom: 13, right: 11)
    static let bookInset = UIEdgeInsets(top: 9, left: 17, bottom: 9, right: 40)
    
    static let bookmarkShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowOffset = .init(width: 0, height: 1)
        shadow.shadowBlurRadius = 12
        shadow.shadowColor = UIColor(Color.blue)
        return shadow
    }()
}
