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
        VStack(alignment: .center, spacing: 12) {
            Image(colorScheme != .dark ? "imgEmptyMain" : "imgEmptyMainDark")
                .frame(width: 44, height: 44)
            Text(emptyCase.emptyString)
                .font(Font.custom("GmarketSansTTFMedium", size: 13))
                .foregroundColor(Color("subText"))
        }
    }
}
