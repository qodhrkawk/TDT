//
//  Theme.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import UIKit

enum Theme: Int, CaseIterable, Codable {
    case blue = 0
    case green
    case yellow
    case pink
    
    var flickImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "imgLogo")
        case .green: return UIImage(named: "imgLogoGr")
        case .yellow: return UIImage(named: "imgLogoYl")
        case .pink: return UIImage(named: "imgLogoPk")
        }
    }
        
    var darkModeFlickImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "dkImgLogo")
        case .green: return UIImage(named: "dkImgLogoGr")
        case .yellow: return UIImage(named: "dkImgLogoYl")
        case .pink: return UIImage(named: "dkImgLogoPk")
        }
    }
    
    var sendButtonImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "btnSendActive")
        case .green: return UIImage(named: "btnSendActiveGr")
        case .yellow: return UIImage(named: "btnSendActiveYl")
        case .pink: return UIImage(named: "btnSendActivePk")
        }
    }
        
    var mainColor: UIColor {
        switch self {
        case .blue: return UIColor.maincolor
        case .green: return UIColor.shamrockGreen
        case .yellow: return UIColor.sunYellow
        case .pink: return UIColor.warmPink
        }
    }

    var settingImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "imgSettings")
        case .green: return UIImage(named: "imgSettingsGr")
        case .yellow: return UIImage(named: "imgSettingsYl")
        case .pink: return UIImage(named: "imgSettingsPk")
        }
    }
        
    var darkModeSettingImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "dkImgSettings")
        case .green: return UIImage(named: "dkImgSettingsGr")
        case .yellow: return UIImage(named: "dkImgSettingsYl")
        case .pink: return UIImage(named: "dkImgSettingsPk")
        }
    }
    
    var editOkayButtonImage: UIImage? {
        switch self {
        case .blue: return UIImage(named: "btnComplete")
        case .green: return UIImage(named: "btnCompleteGr")
        case .yellow: return UIImage(named: "btnCompleteYl")
        case .pink: return UIImage(named: "btnCompletePk")
        }
    }
    
}
