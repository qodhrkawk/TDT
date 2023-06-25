//
//  TraitInfoManager.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/02/02.
//

import Foundation

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
    }
}
