

import UIKit

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        let scanner = Scanner(string: hexString)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x00000000000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red     = CGFloat(r) / 255.0
        let green   = CGFloat(g) / 255.0
        let blue    = CGFloat(b) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: alpha)
    }
}

extension UIColor {
    @nonobjc class var salmon: UIColor {
        return UIColor(red: 232.0 / 255.0, green: 120.0 / 255.0, blue: 120.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var subpink1: UIColor {
        return UIColor(red: 245.0 / 255.0, green: 212.0 / 255.0, blue: 212.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var subgrey: UIColor {
        return UIColor(white: 227.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var mainblack: UIColor {
        return UIColor(white: 55.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var subpink2: UIColor {
        return UIColor(red: 250.0 / 255.0, green: 228.0 / 255.0, blue: 228.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var veryLightPink: UIColor {
        return UIColor(white: 186.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var mango: UIColor {
        return UIColor(red: 244.0 / 255.0, green: 197.0 / 255.0, blue: 76.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var subyellow: UIColor {
        return UIColor(red: 246.0 / 255.0, green: 230.0 / 255.0, blue: 188.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var salmon20: UIColor {
        return UIColor(red: 232.0 / 255.0, green: 120.0 / 255.0, blue: 120.0 / 255.0, alpha: 0.2)
    }
    @nonobjc class var mango20: UIColor {
        return UIColor(red: 244.0 / 255.0, green: 197.0 / 255.0, blue: 76.0 / 255.0, alpha: 0.2)
    }
    @nonobjc class var brownGrey: UIColor {
        return UIColor(white: 177.0 / 255.0, alpha: 1.0)
    }
    
    
    @nonobjc class var white80: UIColor {
        return UIColor(white: 1.0, alpha: 0.8)
    }
    @nonobjc class var brownishGrey: UIColor {
        return UIColor(white: 92.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var black60: UIColor {
        return UIColor(white: 0.0, alpha: 0.6)
    }
    
    @nonobjc class var veryLightPinkTwo: UIColor {
        return UIColor(white: 239.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var brownGreyTwo: UIColor {
        return UIColor(white: 129.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var greenishCyan: UIColor {
        return UIColor(red: 67.0 / 255.0, green: 233.0 / 255.0, blue: 209.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var brownGrey30: UIColor {
        return UIColor(white: 128.0 / 255.0, alpha: 0.3)
    }
    
    @nonobjc class var warmPink: UIColor {
        return UIColor(red: 242.0 / 255.0, green: 78.0 / 255.0, blue: 140.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var brownGreyThree: UIColor {
        return UIColor(white: 128.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var veryLightPinkThree: UIColor {
        return UIColor(white: 199.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var veryLightPink30: UIColor {
        return UIColor(red: 242.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 0.3)
    }
    @nonobjc class var veryLightPinkFour: UIColor {
        return UIColor(white: 236.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var white1: UIColor {
        return UIColor(white: 251.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var brownGreyFour: UIColor {
        return UIColor(white: 171.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var maincolor: UIColor {
        return UIColor(red: 36.0 / 255.0, green: 128.0 / 255.0, blue: 214.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var maincolor20: UIColor {
        return UIColor(red: 36.0 / 255.0, green: 128.0 / 255.0, blue: 214.0 / 255.0, alpha: 0.2)
    }
    @nonobjc class var brownGreyThreeBlur: UIColor {
        return UIColor(white: 128.0 / 255.0, alpha: 0.5)
    }
    @nonobjc class var brownGreyTwo40: UIColor {
        return UIColor(white: 129.0 / 255.0, alpha: 0.4)
    }
    
    @nonobjc class var shamrockGreen: UIColor {
        return UIColor(red: 0.0, green: 192.0 / 255.0, blue: 66.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var sunYellow: UIColor {
        return UIColor(red: 254.0 / 255.0, green: 208.0 / 255.0, blue: 47.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var duckEggBlue: UIColor {
        return UIColor(red: 218.0 / 255.0, green: 227.0 / 255.0, blue: 225.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var veryLightPinkFive: UIColor {
        return UIColor(white: 229.0 / 255.0, alpha: 1.0)
    }
}
