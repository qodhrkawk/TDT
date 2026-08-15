//
//  FlickAccessoryRectangularWidgetView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/11.
//

import SwiftUI

struct FlickAccessoryRectangularWidgetView : View {
    var todoDatas: [WidgetTodoData]
    
    var body: some View {
        FlickWidgetTodoListView(todoDatas: todoDatas, sizeType: .medium)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
