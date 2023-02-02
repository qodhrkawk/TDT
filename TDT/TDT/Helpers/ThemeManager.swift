//
//  ThemeManager.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import Foundation

class ThemeManager {
    static let shared = ThemeManager()
    
    @UserDefaultWrapper<Theme>(key: UserDefaultKeys.theme.rawValue) private(set) var currentTheme
    
    init() {
        migrateThemeFromLegacyIfNeeded()
        if currentTheme == nil {
            currentTheme = .flickBlue
        }
    }
    
    func setCurrentTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    private func migrateThemeFromLegacyIfNeeded() {
        if let _ = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            currentTheme = .flickBlue
            UserDefaults.standard.removeObject(forKey: "mainColor")
        }
    }
}
