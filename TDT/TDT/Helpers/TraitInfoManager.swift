//
//  TraitInfoManager.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/02/02.
//

import Foundation
import WidgetKit

class TraitInfoManager {
    static let shared = TraitInfoManager()
    
    @UserDefaultWrapper<TraitInfo>(key: UserDefaultKeys.trait.rawValue, userDefaults: UserDefaults.grouped) private(set) var currentTraitInfo
    
    init() {
        if currentTraitInfo == nil {
            currentTraitInfo = .system
        }
    }
    
    func setCurrentTraitInfo(_ trait: TraitInfo) {
        currentTraitInfo = trait
        // 위젯도 앱의 화면 스타일을 따르므로 변경 즉시 다시 그린다
        WidgetCenter.shared.reloadAllTimelines()
    }
}
