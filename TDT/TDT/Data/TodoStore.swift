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
/// 화면 구성은 [고정 섹션(있을 때만) + 날짜 섹션들]이며, 모든 public API의 IndexPath는
/// 이 "표시 좌표계"를 쓴다 — 고정 항목이 있으면 섹션 0이 고정 영역, 이후가 날짜 섹션.
/// 고정(pin)은 날짜와 무관한 전역 영역이다. 고정 해제하면 항목의 원래 날짜 섹션으로 돌아간다.
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

    // MARK: - 표시 좌표계

    var hasPinnedSection: Bool { !pinnedDatas.isEmpty }

    private var dateSectionOffset: Int { hasPinnedSection ? 1 : 0 }

    var sectionCount: Int { dateSectionOffset + todoDatas.count }

    var isEmpty: Bool { pinnedDatas.isEmpty && todoDatas.isEmpty }

    func isPinnedSection(_ section: Int) -> Bool {
        hasPinnedSection && section == 0
    }

    func rowCount(inSection section: Int) -> Int {
        if isPinnedSection(section) { return pinnedDatas.count }
        let dateIdx = dateIndex(forDisplaySection: section)
        guard todoDatas.indices.contains(dateIdx) else { return 0 }
        return todoDatas[dateIdx].count
    }

    /// 날짜 섹션이면 날짜 문자열, 고정 섹션이면 nil
    func headerDate(forSection section: Int) -> String? {
        guard !isPinnedSection(section) else { return nil }
        let dateIdx = dateIndex(forDisplaySection: section)
        guard dateInfo.indices.contains(dateIdx) else { return nil }
        return dateInfo[dateIdx]
    }

    func todo(at indexPath: IndexPath) -> TodoData? {
        if isPinnedSection(indexPath.section) {
            guard pinnedDatas.indices.contains(indexPath.row) else { return nil }
            return pinnedDatas[indexPath.row]
        }
        let dateIdx = dateIndex(forDisplaySection: indexPath.section)
        guard todoDatas.indices.contains(dateIdx),
              todoDatas[dateIdx].indices.contains(indexPath.row)
        else { return nil }
        return todoDatas[dateIdx][indexPath.row]
    }

    private func dateIndex(forDisplaySection section: Int) -> Int {
        section - dateSectionOffset
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

    /// 과거 구현(섹션 내 고정)이 날짜 섹션 안에 남긴 isPinned 항목을 전역 고정 영역으로 승격
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
        mutateTodo(at: indexPath) { $0.todo = text }
    }

    func toggleImportant(at indexPath: IndexPath) {
        mutateTodo(at: indexPath) { $0.isImportant.toggle() }
    }

    private func mutateTodo(at indexPath: IndexPath, _ mutation: (inout TodoData) -> Void) {
        if isPinnedSection(indexPath.section) {
            guard pinnedDatas.indices.contains(indexPath.row) else { return }
            mutation(&pinnedDatas[indexPath.row])
        }
        else {
            let dateIdx = dateIndex(forDisplaySection: indexPath.section)
            guard todoDatas.indices.contains(dateIdx),
                  todoDatas[dateIdx].indices.contains(indexPath.row)
            else { return }
            mutation(&todoDatas[dateIdx][indexPath.row])
        }
        save()
    }

    /// 항목을 삭제하고, 섹션(고정 영역 포함)이 비면 섹션까지 사라졌음을 알린다.
    @discardableResult
    func remove(at indexPath: IndexPath) -> (item: TodoData, sectionRemoved: Bool)? {
        if isPinnedSection(indexPath.section) {
            guard pinnedDatas.indices.contains(indexPath.row) else { return nil }
            let item = pinnedDatas.remove(at: indexPath.row)
            save()
            return (item, pinnedDatas.isEmpty)
        }

        let dateIdx = dateIndex(forDisplaySection: indexPath.section)
        guard todoDatas.indices.contains(dateIdx),
              todoDatas[dateIdx].indices.contains(indexPath.row)
        else { return nil }

        let item = todoDatas[dateIdx].remove(at: indexPath.row)

        var sectionRemoved = false
        if todoDatas[dateIdx].isEmpty {
            todoDatas.remove(at: dateIdx)
            dateInfo.remove(at: dateIdx)
            sectionRemoved = true
        }
        save()
        return (item, sectionRemoved)
    }

    // MARK: - 고정 (전역 영역, 날짜 무관)

    /// 고정: 날짜 섹션에서 빼내 고정 영역 맨 위로.
    /// 해제: 항목의 원래 날짜 섹션으로 복귀 (섹션이 없으면 날짜순 위치에 새로 만든다).
    /// 이동한 새 표시 위치를 반환한다.
    @discardableResult
    func togglePin(at indexPath: IndexPath) -> IndexPath? {
        if isPinnedSection(indexPath.section) {
            guard pinnedDatas.indices.contains(indexPath.row) else { return nil }
            var item = pinnedDatas.remove(at: indexPath.row)
            item.isPinned = false
            let destination = insertIntoDateSections(item)
            save()
            return destination
        }

        let dateIdx = dateIndex(forDisplaySection: indexPath.section)
        guard todoDatas.indices.contains(dateIdx),
              todoDatas[dateIdx].indices.contains(indexPath.row)
        else { return nil }

        var item = todoDatas[dateIdx].remove(at: indexPath.row)
        if todoDatas[dateIdx].isEmpty {
            todoDatas.remove(at: dateIdx)
            dateInfo.remove(at: dateIdx)
        }
        item.isPinned = true
        pinnedDatas.insert(item, at: 0)
        save()
        return IndexPath(row: 0, section: 0)
    }

    /// 날짜 순서를 지키며 날짜 섹션에 삽입하고, 삽입된 표시 위치를 반환한다.
    private func insertIntoDateSections(_ item: TodoData) -> IndexPath {
        if let dateIdx = dateInfo.firstIndex(of: item.date) {
            todoDatas[dateIdx].append(item)
            return IndexPath(row: todoDatas[dateIdx].count - 1, section: dateIdx + dateSectionOffset)
        }

        let insertIdx = dateInfo.firstIndex(where: { $0 > item.date }) ?? dateInfo.count
        dateInfo.insert(item.date, at: insertIdx)
        todoDatas.insert([item], at: insertIdx)
        return IndexPath(row: 0, section: insertIdx + dateSectionOffset)
    }

    // MARK: - 순서 변경 (드래그)

    /// 표시 좌표계 기준 드래그 이동.
    /// - 고정 영역 안: 고정 순서 변경
    /// - 고정 영역 → 날짜 섹션: 고정 해제 + 해당 섹션 날짜로 변경
    /// - 날짜 섹션 → 고정 영역: 고정
    /// - 날짜 섹션 간: 날짜 변경 (기존 동작)
    @discardableResult
    func move(from source: IndexPath, to destination: IndexPath) -> IndexPath? {
        guard source != destination, todo(at: source) != nil else { return nil }

        let sourceIsPinned = isPinnedSection(source.section)
        let destinationIsPinned = isPinnedSection(destination.section)
        // 소스 제거로 섹션 인덱스가 밀리기 전에 대상 날짜 섹션을 내부 인덱스로 고정해 둔다
        var destDateIdx: Int? = destinationIsPinned ? nil : dateIndex(forDisplaySection: destination.section)

        var item: TodoData
        if sourceIsPinned {
            item = pinnedDatas.remove(at: source.row)
        }
        else {
            let sourceDateIdx = dateIndex(forDisplaySection: source.section)
            item = todoDatas[sourceDateIdx].remove(at: source.row)
            if todoDatas[sourceDateIdx].isEmpty {
                todoDatas.remove(at: sourceDateIdx)
                dateInfo.remove(at: sourceDateIdx)
                if let idx = destDateIdx, idx > sourceDateIdx {
                    destDateIdx = idx - 1
                }
            }
        }

        if destinationIsPinned {
            item.isPinned = true
            let row = min(destination.row, pinnedDatas.count)
            pinnedDatas.insert(item, at: row)
            save()
            return IndexPath(row: row, section: 0)
        }

        guard let dateIdx = destDateIdx, todoDatas.indices.contains(dateIdx) || todoDatas.count == dateIdx else {
            // 대상 섹션이 사라진 예외 상황 — 원래 날짜 위치로 복귀
            let fallback = insertIntoDateSections(item)
            save()
            return fallback
        }

        item.isPinned = false
        if dateInfo.indices.contains(dateIdx) {
            item.date = dateInfo[dateIdx]
            let row = min(destination.row, todoDatas[dateIdx].count)
            todoDatas[dateIdx].insert(item, at: row)
            save()
            return IndexPath(row: row, section: dateIdx + dateSectionOffset)
        }

        let fallback = insertIntoDateSections(item)
        save()
        return fallback
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
        // 내림차순 처리 — 날짜 섹션들이 먼저, 고정 섹션(0)이 마지막이라
        // 고정 영역이 비어 표시 오프셋이 바뀌어도 남은 인덱스에 영향이 없다
        for indexPath in sortedAscending.reversed() {
            if isPinnedSection(indexPath.section) {
                guard pinnedDatas.indices.contains(indexPath.row) else { continue }
                pinnedDatas.remove(at: indexPath.row)
            }
            else {
                let dateIdx = dateIndex(forDisplaySection: indexPath.section)
                guard todoDatas.indices.contains(dateIdx),
                      todoDatas[dateIdx].indices.contains(indexPath.row)
                else { continue }
                todoDatas[dateIdx].remove(at: indexPath.row)
            }
        }
        removeEmptyDateSections()
        save()
    }
}
