//
//  TextBoxDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import Foundation

protocol TextBoxDelegate: AnyObject {
    func longTapped(indexPath: IndexPath)
    func leftSwiped(indexPath: IndexPath)
    func doubleTapped(indexPath: IndexPath)
    func shouldMove()
}
