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

/// 할 일 데이터의 변형과 영속화를 담당한다. UI 프레임워크 의존이 없어 단독으로 테스트 가능하다.
///
/// - 테이블은 날짜 섹션만 표시한다. public API의 IndexPath는 날짜 섹션 좌표계다.
/// - 고정(pin)은 날짜와 무관한 전역 목록(`pinnedDatas`)으로, 리스트가 아닌
///   스티키 바에 표시된다. 고정 해제하면 항목의 원래 날짜 섹션으로 돌아간다.
final class TodoStore {
    enum Keys {
        static let todos = "TodoDatas"
        static let dates = "dates"
        static let pinned = "PinnedTodoDatas"
        static let archiveTodos = "ArchiveDatas"
        static let archiveDates = "ArchiveDates"
    }

    private let userDefaults: UserDefaults

    private(set) var todoDatas: [[TodoData]] = []
    private(set) var dateInfo: [String] = []
    private(set) var pinnedDatas: [TodoData] = []

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

        if let savedPinned = userDefaults.value(forKey: Keys.pinned) as? Data,
           let decoded = try? PropertyListDecoder().decode([TodoData].self, from: savedPinned) {
            pinnedDatas = decoded
        }
        else {
            pinnedDatas = []
        }

        migrateScatteredPinsIfNeeded()
    }

    /// 과거 구현(섹션 내 고정)이 날짜 섹션 안에 남긴 isPinned 항목을 전역 고정으로 승격
    private func migrateScatteredPinsIfNeeded() {
        var scattered: [TodoData] = []
        for index in todoDatas.indices {
            let pins = todoDatas[index].filter { $0.isPinned }
            guard !pins.isEmpty else { continue }
            scattered.append(contentsOf: pins)
            todoDatas[index].removeAll { $0.isPinned }
        }
        guard !scattered.isEmpty else { return }

        pinnedDatas.insert(contentsOf: scattered, at: 0)
        removeEmptyDateSections()
        save()
    }

    func save() {
        userDefaults.set(try? PropertyListEncoder().encode(todoDatas), forKey: Keys.todos)
        userDefaults.setValue(dateInfo, forKey: Keys.dates)
        userDefaults.set(try? PropertyListEncoder().encode(pinnedDatas), forKey: Keys.pinned)
    }

    // MARK: - 추가 / 수정 / 삭제 (날짜 섹션)

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

    // MARK: - 순서 변경 (드래그)

    /// 드래그 이동. 다른 날짜 섹션으로 이동하면 항목의 날짜가 해당 섹션 날짜로 바뀐다.
    /// 실제 삽입된 위치를 반환한다.
    @discardableResult
    func move(from source: IndexPath, to destination: IndexPath) -> IndexPath? {
        guard source != destination, var item = todo(at: source) else { return nil }

        var destSection = destination.section
        todoDatas[source.section].remove(at: source.row)
        if todoDatas[source.section].isEmpty {
            todoDatas.remove(at: source.section)
            dateInfo.remove(at: source.section)
            if destSection > source.section {
                destSection -= 1
            }
        }

        guard dateInfo.indices.contains(destSection) else {
            let fallback = insertIntoDateSections(item)
            save()
            return fallback
        }

        if source.section != destination.section {
            item.date = dateInfo[destSection]
        }

        let row = min(destination.row, todoDatas[destSection].count)
        todoDatas[destSection].insert(item, at: row)
        save()
        return IndexPath(row: row, section: destSection)
    }

    @discardableResult
    func removeEmptyDateSections() -> [Int] {
        var removed: [Int] = []
        for index in stride(from: todoDatas.count - 1, through: 0, by: -1) where todoDatas[index].isEmpty {
            todoDatas.remove(at: index)
            dateInfo.remove(at: index)
            removed.append(index)
        }
        return removed
    }

    // MARK: - 고정 (전역, 스티키 바)

    func pinnedTodo(at index: Int) -> TodoData? {
        guard pinnedDatas.indices.contains(index) else { return nil }
        return pinnedDatas[index]
    }

    /// 날짜 섹션 항목을 고정 목록 맨 위로 옮긴다.
    func pin(at indexPath: IndexPath) {
        guard var item = todo(at: indexPath) else { return }

        todoDatas[indexPath.section].remove(at: indexPath.row)
        if todoDatas[indexPath.section].isEmpty {
            todoDatas.remove(at: indexPath.section)
            dateInfo.remove(at: indexPath.section)
        }
        item.isPinned = true
        pinnedDatas.insert(item, at: 0)
        save()
    }

    /// 고정 해제 — 항목의 원래 날짜 섹션으로 복귀 (섹션이 없으면 날짜순 위치에 새로 만든다).
    /// 복귀한 위치를 반환한다.
    @discardableResult
    func unpin(at index: Int) -> IndexPath? {
        guard pinnedDatas.indices.contains(index) else { return nil }

        var item = pinnedDatas.remove(at: index)
        item.isPinned = false
        let destination = insertIntoDateSections(item)
        save()
        return destination
    }

    func updatePinnedText(at index: Int, text: String) {
        guard pinnedDatas.indices.contains(index) else { return }
        pinnedDatas[index].todo = text
        save()
    }

    @discardableResult
    func removePinned(at index: Int) -> TodoData? {
        guard pinnedDatas.indices.contains(index) else { return nil }
        let item = pinnedDatas.remove(at: index)
        save()
        return item
    }

    /// 날짜 순서를 지키며 날짜 섹션에 삽입하고, 삽입된 위치를 반환한다.
    private func insertIntoDateSections(_ item: TodoData) -> IndexPath {
        if let dateIdx = dateInfo.firstIndex(of: item.date) {
            todoDatas[dateIdx].append(item)
            return IndexPath(row: todoDatas[dateIdx].count - 1, section: dateIdx)
        }

        let insertIdx = dateInfo.firstIndex(where: { $0 > item.date }) ?? dateInfo.count
        dateInfo.insert(item.date, at: insertIdx)
        todoDatas.insert([item], at: insertIdx)
        return IndexPath(row: 0, section: insertIdx)
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
    /// 새 날짜는 맨 앞(최신순)에 삽입된다 — 기존 동작 유지. 고정 상태는 해제된다.
    func appendToArchive(_ items: [TodoData], dateString: String) {
        guard !items.isEmpty else { return }

        let unpinnedItems = items.map { item -> TodoData in
            var copy = item
            copy.isPinned = false
            return copy
        }

        var (archiveDatas, archiveDates) = loadArchive()

        if let index = archiveDates.firstIndex(of: dateString) {
            archiveDatas[index].append(contentsOf: unpinnedItems)
        }
        else {
            archiveDatas.insert(unpinnedItems, at: 0)
            archiveDates.insert(dateString, at: 0)
        }

        userDefaults.set(try? PropertyListEncoder().encode(archiveDatas), forKey: Keys.archiveTodos)
        userDefaults.setValue(archiveDates, forKey: Keys.archiveDates)
    }

    // MARK: - 일괄 처리 (날짜 섹션)

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
        removeEmptyDateSections()
        save()
    }
}
