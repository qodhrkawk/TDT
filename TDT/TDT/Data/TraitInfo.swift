//
//  TraitInfo.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/02/02.
//

import UIKit

enum TraitInfo: CaseIterable, Codable {
    case system
    case light
    case dark
    
    var text: String {
        switch self {
        case .system: return "시스템 설정 모드"
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .system: return UIImage(named: "imgThemeOS")
        case .light: return UIImage(named: "imgThemeLight")
        case .dark: return UIImage(named: "imgThemeDark")
        }
    }
}
