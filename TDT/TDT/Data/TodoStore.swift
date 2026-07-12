//
//  TodoStore.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/07/12.
//

import Foundation
#if canImport(UIKit)
import UIKit  // IndexPath.row / .section 접근자
#endif

/// 할 일 데이터([[TodoData]] + 날짜 섹션)의 변형과 영속화를 담당한다.
/// UI 프레임워크 의존이 없어 단독으로 테스트 가능하다.
final class TodoStore {
    enum Keys {
        static let todos = "TodoDatas"
        static let dates = "dates"
        static let archiveTodos = "ArchiveDatas"
        static let archiveDates = "ArchiveDates"
    }

    private let userDefaults: UserDefaults

    private(set) var todoDatas: [[TodoData]] = []
    private(set) var dateInfo: [String] = []

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var isEmpty: Bool { todoDatas.isEmpty }

    func todo(at indexPath: IndexPath) -> TodoData? {
        guard todoDatas.indices.contains(indexPath.section),
              todoDatas[indexPath.section].indices.contains(indexPath.row)
        else { return nil }
        return todoDatas[indexPath.section][indexPath.row]
    }

    /// 섹션 상단의 고정 항목 수. 섹션 배열은 항상 [고정..., 일반...] 순서를 유지한다.
    func pinnedCount(inSection section: Int) -> Int {
        guard todoDatas.indices.contains(section) else { return 0 }
        return todoDatas[section].prefix(while: { $0.isPinned }).count
    }

    // MARK: - 로드 / 저장

    func load() {
        if let savedData = userDefaults.value(forKey: Keys.todos) as? Data,
           let decoded = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData) {
            todoDatas = decoded.filter { !$0.isEmpty }
        }
        else {
            todoDatas = []
        }

        dateInfo = userDefaults.stringArray(forKey: Keys.dates) ?? []
        if dateInfo.count != todoDatas.count {
            dateInfo = todoDatas.map { $0.first?.date ?? "" }
        }
    }

    func save() {
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: Keys.todos)
        userDefaults.setValue(dateInfo, forKey: Keys.dates)
    }

    // MARK: - 추가 / 수정 / 삭제

    func add(todo: String, dateString: String) {
        let item = TodoData(date: dateString, todo: todo, isImportant: false)

        if !todoDatas.isEmpty, dateInfo.last == dateString {
            todoDatas[todoDatas.count - 1].append(item)
        }
        else {
            todoDatas.append([item])
            dateInfo.append(dateString)
        }
        save()
    }

    func updateText(at indexPath: IndexPath, text: String) {
        guard todo(at: indexPath) != nil else { return }
        todoDatas[indexPath.section][indexPath.row].todo = text
        save()
    }

    func toggleImportant(at indexPath: IndexPath) {
        guard todo(at: indexPath) != nil else { return }
        todoDatas[indexPath.section][indexPath.row].isImportant.toggle()
        save()
    }

    /// 항목을 삭제하고, 섹션이 비면 섹션까지 제거한다.
    @discardableResult
    func remove(at indexPath: IndexPath) -> (item: TodoData, sectionRemoved: Bool)? {
        guard let item = todo(at: indexPath) else { return nil }

        todoDatas[indexPath.section].remove(at: indexPath.row)

        var sectionRemoved = false
        if todoDatas[indexPath.section].isEmpty {
            todoDatas.remove(at: indexPath.section)
            dateInfo.remove(at: indexPath.section)
            sectionRemoved = true
        }
        save()
        return (item, sectionRemoved)
    }

    // MARK: - 순서 변경

    /// 드래그 이동. 다른 날짜 섹션으로 이동하면 항목의 날짜가 해당 섹션 날짜로 바뀐다.
    /// 고정 항목은 고정 그룹 안으로, 일반 항목은 고정 그룹 아래로 클램프된다.
    /// 실제 삽입된 위치를 반환한다 (빈 섹션 정리 전 기준).
    @discardableResult
    func move(from source: IndexPath, to destination: IndexPath) -> IndexPath? {
        guard source != destination, var item = todo(at: source) else { return nil }

        todoDatas[source.section].remove(at: source.row)

        let targetSection = destination.section
        if source.section != targetSection, dateInfo.indices.contains(targetSection) {
            item.date = dateInfo[targetSection]
        }

        let pinned = pinnedCount(inSection: targetSection)
        var targetRow = item.isPinned
            ? min(destination.row, pinned)
            : max(destination.row, pinned)
        targetRow = min(targetRow, todoDatas[targetSection].count)

        todoDatas[targetSection].insert(item, at: targetRow)
        removeEmptySections()
        save()
        return IndexPath(row: targetRow, section: targetSection)
    }

    @discardableResult
    func removeEmptySections() -> [Int] {
        var removed: [Int] = []
        for index in stride(from: todoDatas.count - 1, through: 0, by: -1) where todoDatas[index].isEmpty {
            todoDatas.remove(at: index)
            dateInfo.remove(at: index)
            removed.append(index)
        }
        return removed
    }

    // MARK: - 고정

    /// 고정 토글. 고정하면 섹션 맨 위로, 해제하면 고정 그룹 바로 아래로 이동한다.
    /// 이동한 새 위치를 반환한다.
    @discardableResult
    func togglePin(at indexPath: IndexPath) -> IndexPath? {
        guard var item = todo(at: indexPath) else { return nil }

        todoDatas[indexPath.section].remove(at: indexPath.row)
        item.isPinned.toggle()

        let row = item.isPinned ? 0 : pinnedCount(inSection: indexPath.section)
        todoDatas[indexPath.section].insert(item, at: row)
        save()
        return IndexPath(row: row, section: indexPath.section)
    }

    // MARK: - 아카이브 (완료 처리)

    func loadArchive() -> (datas: [[TodoData]], dates: [String]) {
        var datas: [[TodoData]] = []
        if let savedData = userDefaults.value(forKey: Keys.archiveTodos) as? Data,
           let decoded = try? PropertyListDecoder().decode([[TodoData]].self, from: savedData) {
            datas = decoded.filter { !$0.isEmpty }
        }

        var dates = userDefaults.stringArray(forKey: Keys.archiveDates) ?? []
        if dates.count != datas.count {
            dates = datas.map { $0.first?.date ?? "" }
        }
        return (datas, dates)
    }

    /// 완료된 항목들을 아카이브의 해당 완료 날짜 섹션에 추가한다.
    /// 새 날짜는 맨 앞(최신순)에 삽입된다 — 기존 동작 유지.
    func appendToArchive(_ items: [TodoData], dateString: String) {
        guard !items.isEmpty else { return }

        var (archiveDatas, archiveDates) = loadArchive()

        if let index = archiveDates.firstIndex(of: dateString) {
            archiveDatas[index].append(contentsOf: items)
        }
        else {
            archiveDatas.insert(items, at: 0)
            archiveDates.insert(dateString, at: 0)
        }

        userDefaults.set(try? PropertyListEncoder().encode(archiveDatas), forKey: Keys.archiveTodos)
        userDefaults.setValue(archiveDates, forKey: Keys.archiveDates)
    }

    // MARK: - 일괄 처리

    /// 선택 항목들을 아카이브로 이동한다.
    func batchArchive(at indexPaths: [IndexPath], dateString: String) {
        let sorted = indexPaths.sorted()
        let items = sorted.compactMap { todo(at: $0) }
        appendToArchive(items, dateString: dateString)
        batchRemove(sorted)
    }

    /// 선택 항목들을 완전히 삭제한다 (아카이브로 가지 않음).
    func batchDelete(at indexPaths: [IndexPath]) {
        batchRemove(indexPaths.sorted())
    }

    private func batchRemove(_ sortedAscending: [IndexPath]) {
        for indexPath in sortedAscending.reversed() {
            guard todoDatas.indices.contains(indexPath.section),
                  todoDatas[indexPath.section].indices.contains(indexPath.row)
            else { continue }
            todoDatas[indexPath.section].remove(at: indexPath.row)
        }
        removeEmptySections()
        save()
    }
}
