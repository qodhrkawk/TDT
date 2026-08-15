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
}
