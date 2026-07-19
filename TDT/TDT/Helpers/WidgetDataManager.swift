//
//  WidgetDataManager.swift
//  TDT
//
//  Created by Yunjae Kim on 2023/03/04.
//

import Foundation
import WidgetKit

public class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    @UserDefaultWrapper<[TodoData]>(
        key: UserDefaultKeys.widgetData.rawValue,
        userDefaults: UserDefaults.grouped
    ) private(set) var widgetData
    
    init() {
        updateData()
    }
    
    func updateData() {
        defer {
            WidgetCenter.shared.reloadAllTimelines()
        }

        // 고정 항목은 날짜와 무관하게 항상 위젯 앞자리에 노출된다
        var pinned: [TodoData] = []
        if let savedPinned = UserDefaults.grouped.value(forKey: "PinnedTodoDatas") as? Data,
           let decoded = try? PropertyListDecoder().decode([TodoData].self, from: savedPinned) {
            pinned = decoded
        }

        var recent: [TodoData] = []
        if let savedData = UserDefaults.grouped.value(forKey: "TodoDatas") as? Data,
           let dataArray = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData),
           dataArray.count != 0 {
            let flattenedArray = Array(dataArray.reduce([], +).reversed())
            let capacity = max(0, 10 - pinned.count)

            if flattenedArray.count > capacity {
                recent = flattenedArray[..<capacity].reversed()
            }
            else {
                recent = flattenedArray.reversed()
            }
        }

        widgetData = Array((pinned + recent).prefix(10))
    }
}
