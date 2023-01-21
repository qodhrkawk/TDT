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
            currentTheme = .blue
        }
    }
    
    func setCurrentTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    private func migrateThemeFromLegacyIfNeeded() {
        if let legacyValue = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            switch legacyValue {
            case 1: currentTheme = .green
            case 2: currentTheme = .yellow
            case 3: currentTheme = .pink
            default: currentTheme = .blue
            }
            
            UserDefaults.standard.removeObject(forKey: "mainColor")
        }
    }
}
