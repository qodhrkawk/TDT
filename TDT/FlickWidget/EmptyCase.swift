//
//  EmptyCase.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/05.
//

import Foundation

enum EmptyCase {
    case entire
    case today
    
    var emptyString: String {
        switch self {
        case .entire: return "할 일을 모두 완료했어요!"
        case .today: return "오늘 할 일이 없어요!"
        }
    }
}
