//
//  ToDoDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import Foundation

protocol ToDoDelegate{
    func delete(idx: IndexPath)
    func modify(idx: IndexPath,str: String)
    
}
