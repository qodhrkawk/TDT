//
//  UIFont+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/22.
//

import UIKit

extension UIFont {
    
    func withFigmaFontSize(_ size: Int) -> UIFont {
        switch size {
        case 100: return withWeight(.thin)
        case 200: return withWeight(.ultraLight)
        case 300: return withWeight(.light)
        case 400: return withWeight(.regular)
        case 500: return withWeight(.medium)
        case 600: return withWeight(.semibold)
        case 700: return withWeight(.bold)
        case 800: return withWeight(.heavy)
        case 900: return withWeight(.black)
        default: return withWeight(.regular)
        }
    }
    
    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        
        traits[.weight] = weight
        
        attributes[.name] = nil
        attributes[.traits] = traits
        attributes[.family] = familyName
        
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
