//
//  TodoStoreTests.swift
//  Xcode 테스트 타겟이 없어 swiftc로 직접 실행하는 스탠드얼론 테스트.
//  실행: ./TDT/Tests/run-tests.sh
//

import Foundation

// macOS CLI에는 UIKit의 IndexPath(row:section:) 확장이 없어 직접 제공
#if !canImport(UIKit)
extension IndexPath {
    init(row: Int, section: Int) { self.init(indexes: [section, row]) }
    var section: Int { self[0] }
    var row: Int { self[1] }
}
#endif

var failures = 0
func expect(_ condition: Bool, _ name: String) {
    if condition {
        print("PASS \(name)")
    } else {
        failures += 1
        print("FAIL \(name)")
    }
}
func ip(_ section: Int, _ row: Int) -> IndexPath { IndexPath(row: row, section: section) }
func td(_ text: String, _ date: String, pinned: Bool = false, important: Bool = false) -> TodoData {
    TodoData(date: date, todo: text, isImportant: important, isPinned: pinned)
}

let suiteName = "todostore.tests"
let defaults = UserDefaults(suiteName: suiteName)!

func freshStore(_ sections: [[TodoData]]) -> TodoStore {
    defaults.removePersistentDomain(forName: suiteName)
    defaults.set(try! PropertyListEncoder().encode(sections), forKey: TodoStore.Keys.todos)
    defaults.setValue(sections.map { $0.first?.date ?? "" }, forKey: TodoStore.Keys.dates)
    let store = TodoStore(userDefaults: defaults)
    store.load()
    return store
}

// MARK: 1. 구버전 데이터(isPinned 없음) 디코딩 호환
struct LegacyTodoData: Codable {
    var date: String
    var todo: String
    var isImportant: Bool
}
defaults.removePersistentDomain(forName: suiteName)
let legacy = [[LegacyTodoData(date: "2026.07.11", todo: "old item", isImportant: true)]]
defaults.set(try! PropertyListEncoder().encode(legacy), forKey: TodoStore.Keys.todos)
defaults.setValue(["2026.07.11"], forKey: TodoStore.Keys.dates)
let legacyStore = TodoStore(userDefaults: defaults)
legacyStore.load()
expect(legacyStore.todoDatas.count == 1
    && legacyStore.todoDatas[0][0].isPinned == false
    && legacyStore.todoDatas[0][0].isImportant == true
    && legacyStore.todoDatas[0][0].todo == "old item",
    "구버전 데이터 디코딩: isPinned 기본값 false, 기존 필드 보존")

// MARK: 2. 추가 — 같은 날짜는 마지막 섹션에, 새 날짜는 새 섹션
var store = freshStore([[td("a", "2026.07.11")]])
store.add(todo: "b", dateString: "2026.07.11")
expect(store.todoDatas.count == 1 && store.todoDatas[0].count == 2, "add: 같은 날짜는 기존 섹션에 추가")
store.add(todo: "c", dateString: "2026.07.12")
expect(store.todoDatas.count == 2 && store.dateInfo == ["2026.07.11", "2026.07.12"], "add: 새 날짜는 새 섹션 생성")

// MARK: 3. 섹션 내 이동
store = freshStore([[td("a", "d1"), td("b", "d1"), td("c", "d1")]])
let dest1 = store.move(from: ip(0, 0), to: ip(0, 2))
expect(store.todoDatas[0].map(\.todo) == ["b", "c", "a"] && dest1 == ip(0, 2), "move: 섹션 내 이동")

// MARK: 4. 섹션 간 이동 시 날짜 변경
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")]])
store.move(from: ip(0, 0), to: ip(1, 1))
expect(store.todoDatas[1].map(\.todo) == ["c", "a"] && store.todoDatas[1][1].date == "d2",
    "move: 섹션 간 이동 시 date가 대상 섹션 날짜로 변경")

// MARK: 5. 일반 항목을 고정 그룹 위로 드롭하면 고정 그룹 아래로 클램프
store = freshStore([[td("pin1", "d1", pinned: true), td("pin2", "d1", pinned: true), td("x", "d1"), td("y", "d1")]])
let dest2 = store.move(from: ip(0, 3), to: ip(0, 0))
expect(store.todoDatas[0].map(\.todo) == ["pin1", "pin2", "y", "x"] && dest2 == ip(0, 2),
    "move: 일반 항목은 고정 그룹 아래로 클램프")

// MARK: 6. 고정 항목은 고정 그룹 안으로 클램프
store = freshStore([[td("pin1", "d1", pinned: true), td("x", "d1"), td("y", "d1")]])
let dest3 = store.move(from: ip(0, 0), to: ip(0, 2))
expect(dest3 == ip(0, 0) && store.todoDatas[0].map(\.todo) == ["pin1", "x", "y"],
    "move: 고정 항목은 고정 그룹 밖으로 나가지 않음")

// MARK: 7. 마지막 항목 이동 시 빈 섹션 제거
store = freshStore([[td("a", "d1")], [td("b", "d2")]])
store.move(from: ip(0, 0), to: ip(1, 1))
expect(store.todoDatas.count == 1 && store.dateInfo == ["d2"] && store.todoDatas[0].map(\.todo) == ["b", "a"],
    "move: 소스 섹션이 비면 섹션/날짜 제거")

// MARK: 8. 핀 토글 — 고정 시 맨 위, 해제 시 고정 그룹 바로 아래
store = freshStore([[td("pin1", "d1", pinned: true), td("x", "d1"), td("y", "d1")]])
let pinnedPath = store.togglePin(at: ip(0, 2))
expect(pinnedPath == ip(0, 0) && store.todoDatas[0].map(\.todo) == ["y", "pin1", "x"] && store.todoDatas[0][0].isPinned,
    "togglePin: 고정하면 섹션 맨 위로")
let unpinnedPath = store.togglePin(at: ip(0, 0))
expect(unpinnedPath == ip(0, 1) && store.todoDatas[0].map(\.todo) == ["pin1", "y", "x"] && !store.todoDatas[0][1].isPinned,
    "togglePin: 해제하면 고정 그룹 바로 아래로")

// MARK: 9. 일괄 아카이브
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")]])
store.batchArchive(at: [ip(0, 0), ip(1, 0)], dateString: "2026.07.12")
let archive = store.loadArchive()
expect(store.todoDatas.count == 1 && store.todoDatas[0].map(\.todo) == ["b"],
    "batchArchive: 원본에서 제거, 빈 섹션 정리")
expect(archive.dates == ["2026.07.12"] && archive.datas[0].map(\.todo) == ["a", "c"],
    "batchArchive: 아카이브 오늘 날짜 섹션에 추가")

// MARK: 10. 기존 아카이브 날짜에 이어붙이기 + 새 날짜는 맨 앞
store = freshStore([[td("d", "d3")]])
store.appendToArchive([td("e", "d3")], dateString: "2026.07.12")
store.appendToArchive([td("f", "d3")], dateString: "2026.07.13")
store.appendToArchive([td("g", "d3")], dateString: "2026.07.12")
let archive2 = store.loadArchive()
expect(archive2.dates == ["2026.07.13", "2026.07.12"]
    && archive2.datas[0].map(\.todo) == ["f"]
    && archive2.datas[1].map(\.todo) == ["e", "g"],
    "appendToArchive: 새 날짜 맨 앞 삽입, 기존 날짜에 이어붙임")

// MARK: 11. 일괄 삭제 (여러 섹션)
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")], [td("d", "d3")]])
store.batchDelete(at: [ip(0, 1), ip(1, 0), ip(2, 0)])
expect(store.todoDatas.count == 1 && store.todoDatas[0].map(\.todo) == ["a"] && store.dateInfo == ["d1"],
    "batchDelete: 여러 섹션에 걸친 삭제 + 빈 섹션 정리")

// MARK: 12. dateInfo 불일치 자가 복구
defaults.removePersistentDomain(forName: suiteName)
defaults.set(try! PropertyListEncoder().encode([[td("a", "d1")], [td("b", "d2")]]), forKey: TodoStore.Keys.todos)
defaults.setValue(["d1"], forKey: TodoStore.Keys.dates)  // 개수 불일치
let healStore = TodoStore(userDefaults: defaults)
healStore.load()
expect(healStore.dateInfo == ["d1", "d2"], "load: dateInfo 개수 불일치 시 데이터에서 재구성")

// MARK: 13. 저장/로드 라운드트립 (isPinned 포함)
store = freshStore([[td("a", "d1", pinned: true, important: true)]])
store.save()
let reloaded = TodoStore(userDefaults: defaults)
reloaded.load()
expect(reloaded.todoDatas[0][0].isPinned && reloaded.todoDatas[0][0].isImportant,
    "save/load 라운드트립: isPinned 유지")

defaults.removePersistentDomain(forName: suiteName)
print(failures == 0 ? "\nALL TESTS PASSED" : "\n\(failures) TEST(S) FAILED")
exit(failures == 0 ? 0 : 1)
