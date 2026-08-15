//
//  View+WidgetBackground.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/08/15.
//

import SwiftUI

extension View {
    // iOS 17 SDK부터 containerBackground를 적용하지 않은 위젯은 내용 대신
    // "Please adopt containerBackground API"를 표시한다. 잠금화면(액세서리)
    // 계열은 시스템이 배경을 그리므로 clear를 넘긴다.
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            self
        }
    }

    // 앱의 "화면 스타일" 설정(라이트/다크 강제)을 위젯에도 적용한다 —
    // 시스템 모드만 따르면 앱과 위젯의 모드가 어긋난다
    @ViewBuilder
    func followAppColorScheme() -> some View {
        switch TraitInfoManager.shared.currentTraitInfo {
        case .light: environment(\.colorScheme, .light)
        case .dark: environment(\.colorScheme, .dark)
        default: self
        }
    }
}
