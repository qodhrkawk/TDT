//
//  UILabel+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/22.
//

import Foundation
import UIKit

extension UILabel {
    func calculateMaxLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -1,
            .font: self.font,
            .foregroundColor: UIColor.blue,
            .paragraphStyle: NSMutableParagraphStyle()
                
        ]
        let text3 = NSAttributedString(string: self.text ?? "",attributes: attributes)
        
        let textSize = text3.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil)
        let linesRoundedUp = Int(ceil(textSize.height/charSize))
        return linesRoundedUp
    }
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
    func addCharacterSpacing(kernValue: Double = 1.15) {
        if let labelText = text, labelText.count > 0 {
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(
                NSAttributedString.Key.kern,
                value: kernValue,
                range: NSRange(location: 0, length: attributedString.length - 1)
            )
            
            attributedText = attributedString
        }
      }
    
    /// 텍스트에 포함된 링크 부분만 파란 하이퍼링크(밑줄)로 강조한다.
    /// 기존 attributedText 스타일(자간·행간) 위에 덧입히므로 setSpacing 뒤에 호출할 것
    func highlightContainedLinks() {
        guard let text, !text.containedLinks.isEmpty else { return }

        let attributedString = NSMutableAttributedString(
            attributedString: attributedText ?? NSAttributedString(string: text)
        )
        for link in text.containedLinks {
            attributedString.addAttributes([
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: UIColor.systemBlue
            ], range: link.range)
        }
        attributedText = attributedString
    }

    func setSpacing(spacing: CGFloat,kernValue: Double){
        if let labelText = text, labelText.count > 0 {
            let attributedString = NSMutableAttributedString(string: labelText)
            
            attributedString.addAttribute(
                NSAttributedString.Key.kern,
                value: kernValue,
                range: NSRange(location: 0, length: attributedString.length - 1)
            )

            let style = NSMutableParagraphStyle()
            style.lineSpacing = spacing
            attributedString.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: style,
                range: NSMakeRange(0, attributedString.length))
            attributedText = attributedString
        }
        
    }
    
}
