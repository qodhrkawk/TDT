//
//  WidgetTodoRow.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import SwiftUI

struct WidgetTodoRow: View {
    var todo: String
    var isImportant: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isImportant ? Color(ThemeManager.shared.currentTheme?.mainColor ?? UIColor.gray) : Color("inactiveColor") )
                .frame(width: 8, height: 8)
            Text(todo)
                .font(Font.custom("GmarketSansTTFMedium", size: 15))
                .foregroundColor(Color("mainText"))
        }
    }
}
