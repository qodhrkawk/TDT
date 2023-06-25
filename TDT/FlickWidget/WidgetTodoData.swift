//
//  WidgetTodoData.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/04.
//

import Foundation

struct WidgetTodoData: Hashable, Identifiable {
    static func == (lhs: WidgetTodoData, rhs: WidgetTodoData) -> Bool {
        lhs.id == rhs.id
    }
    
    var id = UUID()
    let todo: String
    let dateString: String
    let isImportant: Bool
    
    init(todoData: TodoData) {
        todo = todoData.todo
        dateString = todoData.date
        isImportant = todoData.isImportant
    }
}
