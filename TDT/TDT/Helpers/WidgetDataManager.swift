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

        if let savedData = UserDefaults.grouped.value(forKey: "TodoDatas") as? Data {
            guard
                let dataArray = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData),
                dataArray.count != 0
            else {
                widgetData = []
                return
            }

            let flattenedArray = Array(dataArray.reduce([], +).reversed())

            if flattenedArray.count > 10 {
                widgetData = flattenedArray[..<10].reversed()
            }
            else {
                widgetData = flattenedArray.reversed()
            }
        }
        else {
            widgetData = []
        }
    }
}
