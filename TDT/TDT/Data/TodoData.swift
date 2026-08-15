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
    var isPinned: Bool

    public init(date: String, todo: String, isImportant: Bool, isPinned: Bool = false) {
        self.date = date
        self.todo = todo
        self.isImportant = isImportant
        self.isPinned = isPinned
    }

    // isPinned는 3.0에서 추가된 필드 — 구버전 데이터에는 키가 없으므로 기본값으로 디코딩
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        todo = try container.decode(String.self, forKey: .todo)
        isImportant = try container.decode(Bool.self, forKey: .isImportant)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}
