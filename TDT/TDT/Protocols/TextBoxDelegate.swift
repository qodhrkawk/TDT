//
//  TextBoxDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import Foundation

protocol TextBoxDelegate {
    func longTapped(idx: IndexPath)
    func leftSwiped(idx: IndexPath)
    func doubleTapped(idx: IndexPath)
    func shouldMove()
    
}
