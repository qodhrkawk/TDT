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
}
