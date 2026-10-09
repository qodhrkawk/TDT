//
//  FlickSmallWidgetView.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/09/16.
//

import SwiftUI

struct FlickSmallWidgetView : View {
    var todoDatas: [WidgetTodoData]

    var body: some View {
        FlickWidgetTodoListView(todoDatas: todoDatas, sizeType: .medium)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: 16, leading: 14, bottom: 14, trailing: 12))
    }
}
