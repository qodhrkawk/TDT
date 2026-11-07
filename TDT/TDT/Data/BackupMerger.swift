//
//  BackupMerger.swift
//  TDT
//
//  가져온 백업 내용을 기기 데이터에 합친다. 기기 데이터는 지우거나 바꾸지 않고 새 항목만 더한다.
//  (안내 세트 정리만 예외: 새 항목이 실제로 추가될 때 기기의 안내 할 일 3개를 지운다.)
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

    static func merge(current: BackupContent, incoming: BackupContent) -> BackupMergeResult {
        var merged = current
        let incomingTodos = removingGuideSet(from: incoming.todos, all: true)

        // 기기의 일반+고정, 아카이브 항목 개수
        var todoCounts: [Key: Int] = [:]
        for section in current.todos {
            for item in section.items { todoCounts[todoKey(item), default: 0] += 1 }
        }
        for item in current.pinned { todoCounts[todoKey(item), default: 0] += 1 }
        var archiveCounts: [Key: Int] = [:]
        for section in current.archive {
            for item in section.items { archiveCounts[archiveKey(section, item), default: 0] += 1 }
        }

        var added = 0
        var skipped = 0

        // 날짜(앞 10자) -> 섹션 위치
        var todoIndex = sectionIndex(merged.todos)
        var archiveIndex = sectionIndex(merged.archive)

        for section in incomingTodos {
            for item in section.items {
                if consume(&todoCounts, todoKey(item)) {
                    skipped += 1
                } else {
                    insert(item, intoSectionDated: section.date, of: &merged.todos, index: &todoIndex, ascending: true)
                    added += 1
                }
            }
        }
        for item in incoming.pinned {
            if consume(&todoCounts, todoKey(item)) {
                skipped += 1
            } else {
                merged.pinned.append(item)
                added += 1
            }
        }
        for section in incoming.archive {
            for item in section.items {
                if consume(&archiveCounts, archiveKey(section, item)) {
                    skipped += 1
                } else {
                    insert(item, intoSectionDated: section.date, of: &merged.archive, index: &archiveIndex, ascending: false)
                    added += 1
                }
            }
        }

        if added > 0 {
            merged.todos = removingGuideSet(from: merged.todos, all: false)
        }
        return BackupMergeResult(merged: merged, added: added, skipped: skipped)
    }

    // MARK: - 안내 세트

    /// 세 문구가 모두 있는 섹션에서 각 문구를 하나씩 뺀다. 빈 섹션은 버린다.
    /// `all`이 false면 처음 발견한 세트 하나만 지운다.
    private static func removingGuideSet(from sections: [BackupSection], all: Bool) -> [BackupSection] {
        var result: [BackupSection] = []
        var done = false
        for section in sections {
            let texts = Set(section.items.map(\.todo))
            guard !done, guideTexts.allSatisfy(texts.contains) else {
                result.append(section)
                continue
            }
            var copy = section
            for guide in guideTexts {
                if let index = copy.items.firstIndex(where: { $0.todo == guide }) {
                    copy.items.remove(at: index)
                }
            }
            if !copy.items.isEmpty { result.append(copy) }
            if !all { done = true }
        }
        return result
    }

    // MARK: - 비교와 삽입

    private static func day(_ string: String) -> String { String(string.prefix(10)) }

    private static func todoKey(_ item: BackupItem) -> Key {
        Key(completed: "", date: day(item.date), todo: item.todo)
    }

    private static func archiveKey(_ section: BackupSection, _ item: BackupItem) -> Key {
        Key(completed: day(section.date), date: day(item.date), todo: item.todo)
    }

    /// 사전에 남은 개수가 있으면 하나 줄이고 true (같은 항목이 이미 있다)
    private static func consume(_ counts: inout [Key: Int], _ key: Key) -> Bool {
        guard let count = counts[key], count > 0 else { return false }
        counts[key] = count - 1
        return true
    }

    private static func sectionIndex(_ sections: [BackupSection]) -> [String: Int] {
        var index: [String: Int] = [:]
        for (i, section) in sections.enumerated() where index[day(section.date)] == nil {
            index[day(section.date)] = i
        }
        return index
    }

    /// 같은 날짜 섹션 끝에 붙인다. 없으면 정렬 순서를 지키는 위치에 새 섹션을 만든다.
    /// (할 일: 오름차순, 아카이브: 내림차순)
    private static func insert(_ item: BackupItem, intoSectionDated date: String,
                               of sections: inout [BackupSection], index: inout [String: Int], ascending: Bool) {
        let key = day(date)
        if let i = index[key] {
            sections[i].items.append(item)
            return
        }
        let position = sections.firstIndex { ascending ? day($0.date) > key : day($0.date) < key } ?? sections.count
        sections.insert(BackupSection(date: date, items: [item]), at: position)
        index = sectionIndex(sections)
    }
}
