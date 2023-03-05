//
//  ThemeManager.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/01/21.
//

import Foundation
import WidgetKit

public class ThemeManager {
    public static let shared = ThemeManager()
    
    @UserDefaultWrapper<Theme>(
        key: UserDefaultKeys.theme.rawValue,
        userDefaults: UserDefaults.grouped
    ) private(set) var currentTheme
    
    @UserDefaultWrapper<Theme>(
        key: UserDefaultKeys.theme.rawValue,
        userDefaults: UserDefaults.standard
    ) private(set) var legacyTheme
    
    init() {
        migrateThemeFromLegacyIfNeeded()
        if currentTheme == nil {
            currentTheme = .flickBlue
        }
    }
    
    func setCurrentTheme(_ theme: Theme) {
        currentTheme = theme
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func migrateThemeFromLegacyIfNeeded() {
        // Legacy from Ver 1.x.x
        if let _ = UserDefaults.standard.value(forKey: "mainColor") as? Int {
            currentTheme = .flickBlue
            UserDefaults.standard.removeObject(forKey: "mainColor")
        }
        // Legacy from Ver 2.0.0
        if let legacyTheme {
            currentTheme = legacyTheme
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.theme.rawValue)
        }
    }
}
