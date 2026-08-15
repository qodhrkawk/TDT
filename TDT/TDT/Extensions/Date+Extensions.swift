//
//  Date+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import Foundation

extension Date {
    func stringValue() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"

        return dateFormatter.string(from: self)
    }
}
