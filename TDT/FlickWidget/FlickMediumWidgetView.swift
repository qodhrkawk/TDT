//
//  FlickMediumWidgetView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/04.
//

import SwiftUI

struct FlickMediumWidgetView : View {
    var todoDatas: [WidgetTodoData]
    
    var body: some View {
        FlickWidgetTodoListView(todoDatas: todoDatas)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 18, leading: 24, bottom: 15, trailing: 28))
    }
}

struct FlickWidgetTodoListView: View {
    var todoDatas: [WidgetTodoData]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(todoDatas) { todoData in
                WidgetTodoRow(todo: todoData.todo, isImportant: todoData.isImportant)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 24, maxHeight: 24, alignment: .leading)
            }
        }
    }
}
