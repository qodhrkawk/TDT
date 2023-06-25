//
//  TodoData.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/24.
//

import Foundation


struct WholeData: Codable {
    var dict: [Int : [TodoData]]
    
    init(dict: Dictionary<Int, [TodoData]>) {
        self.dict = dict
    }
}

public struct TodoData: Codable {
    var date: String
    var todo: String
    var isImportant: Bool
    
    public init(date: String, todo: String, isImportant: Bool) {
        self.date = date
        self.todo = todo
        self.isImportant = isImportant
    }
}
