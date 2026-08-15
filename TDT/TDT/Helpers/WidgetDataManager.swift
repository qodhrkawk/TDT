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
    
    // 위젯 익스텐션에서도 이 클래스가 로드된다. init에서 updateData()를 부르면
    // 잠금 상태(재부팅 직후 등)에서 위젯이 깨어났을 때 앱 그룹 읽기가 실패하면서
    // 캐시를 빈 배열로 덮어써 "할 일을 모두 완료했어요!"가 고착되는 버그가 있었다.
    // 갱신은 앱 프로세스만 명시적으로 호출한다 — 위젯은 읽기 전용.
    init() {}
    
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

        let savedData = UserDefaults.grouped.value(forKey: "TodoDatas") as? Data

        // 앱은 TodoDatas 키를 항상 기록하므로, 읽기가 nil인데 캐시가 남아 있다면
        // 실제 삭제가 아니라 읽기 실패다 — 캐시를 지우지 않는다.
        if savedData == nil, let cached = widgetData, !cached.isEmpty {
            return
        }

        var recent: [TodoData] = []
        if let savedData,
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
