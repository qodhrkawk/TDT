//
//  Theme.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import UIKit

enum Theme: Int, CaseIterable, Codable {
    case tomato = 0
    case mustard
    case forest
    case flickBlue
    case violet
    case pink
    case babyBlue
    
    var colorName: String {
        switch self {
        case .tomato: return "토마토"
        case .mustard: return "머스타드"
        case .forest: return "포레스트"
        case .flickBlue: return "플릭 블루"
        case .violet: return "파스텔 바이올렛"
        case .pink: return "인디 핑크"
        case .babyBlue: return "베이비 블루"
        }
    }
        
    var mainColor: UIColor {
        switch self {
        case .tomato: return UIColor(hexString: "#D94A2A")
        case .mustard: return UIColor(hexString: "#EF9E00")
        case .forest: return UIColor(hexString: "#03A239")
        case .flickBlue: return UIColor(hexString: "#0069CA")
        case .violet: return UIColor(hexString: "#8458CC")
        case .pink: return UIColor(hexString: "#F092B4")
        case .babyBlue: return UIColor(hexString: "#64B3CC")
        }
    }
}
