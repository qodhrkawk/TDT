//
//  FlickTodayMediumEmptyView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/11.
//

import SwiftUI

struct FlickTodayMediumEmptyView : View {
    var body: some View {
        VStack(alignment: .leading, spacing: -24) {
            Text(Date().stringValue())
                .font(Font.custom("GmarketSansTTFBold", size: 14))
                .foregroundColor(Color(ThemeManager.shared.currentTheme?.mainColor ?? Theme.flickBlue.mainColor))
                .padding(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 0))
            Spacer()
            FlickWidgetEmptyView(emptyCase: .today)
                .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            Spacer()
        }
        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
    }
}
