//
//  TextBoxDelegate.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/23.
//

import UIKit

// indexPath 대신 cell을 넘긴다 — 셀에 저장해둔 indexPath는 셀 재사용/데이터 변경 시
// 실제 위치와 어긋나 엉뚱한 항목이 삭제되는 버그가 있었다.
// 수신 측이 tableView.indexPath(for:)로 시점에 맞는 위치를 조회한다.
protocol TextBoxDelegate: AnyObject {
    func longTapped(cell: UITableViewCell)
    func leftSwiped(cell: UITableViewCell)
    func doubleTapped(cell: UITableViewCell)
    func shouldMove()
}
