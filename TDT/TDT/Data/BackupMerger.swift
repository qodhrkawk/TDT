//
//  BackupMerger.swift
//  TDT
//
//  가져온 백업 내용을 기기 데이터에 합친다. 기기 데이터는 지우거나 바꾸지 않고 새 항목만 더한다.
//  (안내 세트 정리만 예외: 새 항목이 실제로 추가될 때 기기의 안내 할 일 세트를 지운다.)
//

import Foundation

struct BackupMergeResult {
    var merged: BackupContent
    var added: Int
    var skipped: Int
}

enum BackupMerger {
    /// 새로 설치한 앱에 들어 있는 안내 할 일 3개 (안드로이드와 같은 문구)
    static let guideTexts: [String] = [
        "왼쪽으로 밀어서 완료 상태로 만들어 보세요.",
        "두 번 탭해서 중요 표시를 해 보세요.",
        "한 번 클릭해서 메모를 삭제하거나 수정할 수 있어요."
    ]

    private struct Key: Hashable {
        var completed: String   // 아카이브만 사용, 그 외에는 빈 문자열
        var date: String
        var todo: String
    }

    /// `today`는 기기 데이터를 내보낼 때와 같은 규칙으로 정리해 비교하는 데 쓴다. 저장된 기기 데이터는 고치지 않는다.
    static func merge(current: BackupContent, incoming: BackupContent, today: String) -> BackupMergeResult {
        let fileTodos = removingGuideSets(from: incoming.todos)

        // 기기 안내 세트를 뺀 사본에서 비교하고 삽입한다
        var merged = current
        merged.todos = removingGuideSets(from: current.todos)
        let comparable = FlickBackup.sanitized(merged, today: today)

        var todoCounts: [Key: Int] = [:]
        for section in comparable.todos {
            for item in section.items { todoCounts[todoKey(item), default: 0] += 1 }
        }
        for item in comparable.pinned { todoCounts[todoKey(item), default: 0] += 1 }
        var archiveCounts: [Key: Int] = [:]
        for section in comparable.archive {
            for item in section.items { archiveCounts[archiveKey(section, item), default: 0] += 1 }
        }

        var added = 0
        var skipped = 0
        var todoInserter = SectionInserter(sections: merged.todos, ascending: true)
        var archiveInserter = SectionInserter(sections: merged.archive, ascending: false)
        var newPinned: [BackupItem] = []

        for section in fileTodos {
            for item in section.items {
                if consume(&todoCounts, todoKey(item)) {
                    skipped += 1
                } else {
                    todoInserter.add(item, sectionDate: section.date)
                    added += 1
                }
            }
        }
        for item in incoming.pinned {
            if consume(&todoCounts, todoKey(item)) {
                skipped += 1
            } else {
                newPinned.append(item)
                added += 1
            }
        }
        for section in incoming.archive {
            for item in section.items {
                if consume(&archiveCounts, archiveKey(section, item)) {
                    skipped += 1
                } else {
                    archiveInserter.add(item, sectionDate: section.date)
                    added += 1
                }
            }
        }

        guard added > 0 else {
            return BackupMergeResult(merged: current, added: 0, skipped: skipped)
        }
        merged.todos = todoInserter.result()
        merged.pinned += newPinned
        merged.archive = archiveInserter.result()
        return BackupMergeResult(merged: merged, added: added, skipped: skipped)
    }

    // MARK: - 안내 세트

    /// 안내 세트: 한 섹션 안에서 세 문구가 같은 `date`로, 중요 표시 없이 모두 있는 경우.
    /// 중요 표시를 한 항목은 사용자가 손댄 것으로 본다.
    private static func guideSetDate(in items: [BackupItem]) -> String? {
        for item in items where item.todo == guideTexts[0] && !item.isImportant {
            let date = item.date
            let complete = guideTexts.allSatisfy { text in
                items.contains { $0.todo == text && $0.date == date && !$0.isImportant }
            }
            if complete { return date }
        }
        return nil
    }

    /// 모든 섹션에서 안내 세트를 (여러 개여도 모두) 하나씩 빼고, 빈 섹션은 버린다.
    private static func removingGuideSets(from sections: [BackupSection]) -> [BackupSection] {
        sections.compactMap { section in
            var copy = section
            while let date = guideSetDate(in: copy.items) {
                for text in guideTexts {
                    if let index = copy.items.firstIndex(where: { $0.todo == text && $0.date == date && !$0.isImportant }) {
                        copy.items.remove(at: index)
                    }
                }
            }
            return copy.items.isEmpty && !section.items.isEmpty ? nil : copy
        }
    }

    // MARK: - 비교

    private static func todoKey(_ item: BackupItem) -> Key {
        Key(completed: "", date: item.date, todo: item.todo)
    }

    private static func archiveKey(_ section: BackupSection, _ item: BackupItem) -> Key {
        Key(completed: section.date, date: item.date, todo: item.todo)
    }

    /// 사전에 남은 개수가 있으면 하나 줄이고 true (같은 항목이 이미 있다)
    private static func consume(_ counts: inout [Key: Int], _ key: Key) -> Bool {
        guard let count = counts[key], count > 0 else { return false }
        counts[key] = count - 1
        return true
    }

    // MARK: - 삽입

    /// 같은 날짜 섹션 끝에 붙이고, 없는 날짜는 모아 두었다가 정렬 순서를 지키는 위치에 한 번에 끼운다.
    /// (할 일: 첫 더 큰 날짜 앞, 아카이브: 첫 더 작은 날짜 앞)
    private struct SectionInserter {
        var sections: [BackupSection]
        let ascending: Bool
        private var existing: [String: Int] = [:]
        private var pending: [String: [BackupItem]] = [:]
        private var pendingOrder: [String] = []

        init(sections: [BackupSection], ascending: Bool) {
            self.sections = sections
            self.ascending = ascending
            for (i, section) in sections.enumerated() {
                let day = String(section.date.prefix(10))
                if FlickBackup.isValidDate(day), existing[day] == nil { existing[day] = i }
            }
        }

        mutating func add(_ item: BackupItem, sectionDate: String) {
            if let i = existing[sectionDate] {
                sections[i].items.append(item)
            } else if pending[sectionDate] != nil {
                pending[sectionDate]!.append(item)
            } else {
                pending[sectionDate] = [item]
                pendingOrder.append(sectionDate)
            }
        }

        func result() -> [BackupSection] {
            guard !pending.isEmpty else { return sections }
            let days = sections.map { String($0.date.prefix(10)) }
            // 새 날짜가 들어갈 위치: 첫 더 큰(작은) 날짜 앞. 기존 섹션은 정렬되어 있다고 보고 이분 탐색한다.
            func position(_ date: String) -> Int {
                var low = 0, high = days.count
                while low < high {
                    let mid = (low + high) / 2
                    if ascending ? days[mid] > date : days[mid] < date { high = mid } else { low = mid + 1 }
                }
                return low
            }
            var byPosition: [Int: [String]] = [:]
            for date in pendingOrder { byPosition[position(date), default: []].append(date) }

            var out: [BackupSection] = []
            out.reserveCapacity(sections.count + pendingOrder.count)
            for i in 0...sections.count {
                if let dates = byPosition[i] {
                    for date in dates.sorted(by: { ascending ? $0 < $1 : $0 > $1 }) {
                        out.append(BackupSection(date: date, items: pending[date]!))
                    }
                }
                if i < sections.count { out.append(sections[i]) }
            }
            return out
        }
    }
}
