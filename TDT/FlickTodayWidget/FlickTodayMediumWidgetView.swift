//
//  FlickTodayMediumWidgetView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import SwiftUI

struct FlickTodayMediumWidgetView : View {
    var todoDatas: [WidgetTodoData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(Date().stringValue())
                .font(Font.custom("GmarketSansTTFBold", size: 14))
                .foregroundColor(Color(ThemeManager.shared.currentTheme?.mainColor ?? Theme.flickBlue.mainColor))
                .padding(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 0))
            FlickWidgetTodoListView(todoDatas: todoDatas)
                .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 28))
        }
        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(EdgeInsets(top: 18, leading: 0, bottom: 15, trailing: 0))
    }
}
