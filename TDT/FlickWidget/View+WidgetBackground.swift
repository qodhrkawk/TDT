//
//  View+WidgetBackground.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/08/15.
//

import SwiftUI
import UIKit

enum WidgetAppearance {
    // 앱의 "화면 스타일" 설정 — system이면 nil (시스템 추종)
    static var forcedStyle: UIUserInterfaceStyle? {
        switch TraitInfoManager.shared.currentTraitInfo {
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }

    // containerBackground는 시스템 트레이트로 그려지므로 environment 오버라이드가
    // 통하지 않는다 — 강제 스타일로 미리 해석한 고정 색을 넘겨야 한다.
    static func background() -> Color {
        let base = UIColor(named: "bgColor") ?? .systemBackground
        guard let style = forcedStyle else { return Color(base) }
        return Color(base.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)))
    }
}

extension View {
    // iOS 17 SDK부터 containerBackground를 적용하지 않은 위젯은 내용 대신
    // "Please adopt containerBackground API"를 표시한다. 잠금화면(액세서리)
    // 계열은 시스템이 배경을 그리므로 clear를 넘긴다.
    func widgetBackground(_ color: Color) -> some View {
        containerBackground(for: .widget) { color }
    }

    // 앱의 "화면 스타일" 설정(라이트/다크 강제)을 위젯 콘텐츠에 적용 —
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
