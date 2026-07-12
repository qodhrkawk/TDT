//
//  ToDoDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import Foundation

protocol ToDoDelegate: AnyObject {
    func delete(indexPath: IndexPath)
    func modify(indexPath: IndexPath,str: String)
    func dismissed(indexPath: IndexPath)
    func togglePin(indexPath: IndexPath)
}

// 고정은 할 일 목록에서만 지원한다 (아카이브에는 없음)
extension ToDoDelegate {
    func togglePin(indexPath: IndexPath) {}
}
