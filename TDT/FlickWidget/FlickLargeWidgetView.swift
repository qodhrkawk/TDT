//
//  FlickLargeWidgetView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import SwiftUI
import WidgetKit

struct FlickLargeWidgetView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var todoDatas: [WidgetTodoData]
    
    var body: some View {
        FlickWidgetTodoListView(todoDatas: todoDatas)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 18, leading: 24, bottom: 15, trailing: 28))

        FlickLargeWidgetButtonView()
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 44, maxHeight: 44)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
}

struct FlickLargeWidgetButtonView : View {
    var body: some View {
        HStack(spacing: 8) {
            Link(destination: URL(string: "FlickWidget://archive")!) {
                Text("아카이브 보기")
                    .font(Font.custom("GmarketSansTTFMedium", size: 15))
                    .foregroundColor(Color("mainText"))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color("inactiveColor"))
                    .cornerRadius(8)
                    .padding(0)

            }

            Link(destination: URL(string: "FlickWidget://todo")!) {
                Text("새 메모 등록하기")
                    .font(Font.custom("GmarketSansTTFMedium", size: 15))
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color(ThemeManager.shared.currentTheme?.mainColor ?? UIColor.gray))
                    .cornerRadius(8)
                    .padding(0)
            }
        }
    }
}
