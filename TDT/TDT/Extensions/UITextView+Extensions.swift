//
//  UITextView+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import Foundation
import UIKit

extension UITextView {
    func setLinespace(spacing: CGFloat) {
        if let text = self.text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            style.lineSpacing = spacing
            attributeString.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: style,
                range: NSMakeRange(0, attributeString.length)
            )

            self.attributedText = attributeString
        }
        
    }
    
}
