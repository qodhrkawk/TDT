//
//  FlickWidgetEmptyView.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import SwiftUI

struct FlickWidgetEmptyView: View {
    @Environment(\.colorScheme) var colorScheme
    var emptyCase: EmptyCase

    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            Image(colorScheme != .dark ? "imgEmptyMain" : "imgEmptyMainDark")
            Text(emptyCase.emptyString)
                .font(Font.custom("GmarketSansTTFMedium", size: 15))
                .foregroundColor(Color("subText"))
        }
    }
}
