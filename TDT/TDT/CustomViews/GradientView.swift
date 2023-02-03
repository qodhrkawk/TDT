//
//  GradientView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/24.
//

import UIKit

class GradientView: UIView {
    
    override var bounds: CGRect {
        didSet {
            guard
                let currentTheme = ThemeManager.shared.currentTheme,
                let secondColor = UIColor(named: "bgColor")
            else { return }

            setGradient(color1: currentTheme.mainColor, color2: secondColor)
        }
    }
  
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override var layer: CAGradientLayer {
        return super.layer as! CAGradientLayer
    }
}

class ReverseGradientView: UIView {
    
    override var bounds: CGRect {
        didSet {
            guard
                let firstColor = UIColor(named: "bgColor"),
                let currentTheme = ThemeManager.shared.currentTheme
            else { return }

            setGradient(color1: firstColor, color2: currentTheme.mainColor)
        }
    }
  
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override var layer: CAGradientLayer {
        return super.layer as! CAGradientLayer
    }
}
