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
//            print("BOUNDS Changed")
//            print(bounds)
        }
    }
  
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override var layer: CAGradientLayer {
        return super.layer as! CAGradientLayer
    }
}
