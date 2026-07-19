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

func freshStore(_ sections: [[TodoData]], pinned: [TodoData] = []) -> TodoStore {
    defaults.removePersistentDomain(forName: suiteName)
    defaults.set(try! PropertyListEncoder().encode(sections), forKey: TodoStore.Keys.todos)
    defaults.setValue(sections.map { $0.first?.date ?? "" }, forKey: TodoStore.Keys.dates)
    if !pinned.isEmpty {
        defaults.set(try! PropertyListEncoder().encode(pinned), forKey: TodoStore.Keys.pinned)
    }
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
    && legacyStore.pinnedDatas.isEmpty,
    "구버전 데이터 디코딩: isPinned 기본값 false, 고정 목록 비어 있음")

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

// MARK: 4. 날짜 섹션 간 이동 시 날짜 변경
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")]])
store.move(from: ip(0, 0), to: ip(1, 1))
expect(store.todoDatas[1].map(\.todo) == ["c", "a"] && store.todoDatas[1][1].date == "d2",
    "move: 날짜 섹션 간 이동 시 date 변경")

// MARK: 5. 마지막 항목 이동 시 빈 섹션 제거
store = freshStore([[td("a", "d1")], [td("b", "d2")]])
store.move(from: ip(0, 0), to: ip(1, 1))
expect(store.todoDatas.count == 1 && store.dateInfo == ["d2"] && store.todoDatas[0].map(\.todo) == ["b", "a"],
    "move: 소스 섹션이 비면 섹션/날짜 제거")

// MARK: 6. 고정 — 날짜 섹션에서 고정 목록 맨 위로 (원래 날짜 보존)
store = freshStore([[td("a", "d1"), td("b", "d1")]], pinned: [td("p", "d0", pinned: true)])
store.pin(at: ip(0, 1))
expect(store.pinnedDatas.map(\.todo) == ["b", "p"]
    && store.pinnedDatas[0].isPinned
    && store.pinnedDatas[0].date == "d1"
    && store.todoDatas[0].map(\.todo) == ["a"],
    "pin: 고정 목록 맨 위로, 원래 날짜 보존")

// MARK: 7. 고정 시 소스 섹션이 비면 섹션 제거
store = freshStore([[td("only", "d1")], [td("b", "d2")]])
store.pin(at: ip(0, 0))
expect(store.todoDatas.count == 1 && store.dateInfo == ["d2"] && store.pinnedDatas.map(\.todo) == ["only"],
    "pin: 마지막 항목 고정 시 빈 섹션 제거")

// MARK: 8. 고정 해제 — 원래 날짜 섹션으로 복귀
store = freshStore([[td("a", "d1")]], pinned: [td("p", "d1", pinned: true)])
let unpinPath = store.unpin(at: 0)
expect(unpinPath == ip(0, 1)
    && store.pinnedDatas.isEmpty
    && store.todoDatas[0].map(\.todo) == ["a", "p"]
    && !store.todoDatas[0][1].isPinned,
    "unpin: 기존 날짜 섹션 끝으로 복귀")

// MARK: 9. 고정 해제 — 날짜 섹션이 없으면 날짜순 위치에 재생성
store = freshStore([[td("a", "d1")], [td("c", "d3")]], pinned: [td("p", "d2", pinned: true)])
let recreatePath = store.unpin(at: 0)
expect(store.dateInfo == ["d1", "d2", "d3"]
    && store.todoDatas[1].map(\.todo) == ["p"]
    && recreatePath == ip(1, 0),
    "unpin: 사라진 날짜 섹션을 날짜순으로 재생성")

// MARK: 10. 고정 항목 수정/삭제
store = freshStore([[td("a", "d1")]], pinned: [td("p1", "d0", pinned: true), td("p2", "d0", pinned: true)])
store.updatePinnedText(at: 1, text: "p2-수정")
expect(store.pinnedDatas[1].todo == "p2-수정", "updatePinnedText: 고정 항목 텍스트 수정")
let removedPin = store.removePinned(at: 0)
expect(removedPin?.todo == "p1" && store.pinnedDatas.map(\.todo) == ["p2-수정"],
    "removePinned: 고정 항목 삭제")

// MARK: 11. 마이그레이션 — 날짜 섹션 안 isPinned 항목을 전역 고정으로 승격
defaults.removePersistentDomain(forName: suiteName)
defaults.set(try! PropertyListEncoder().encode([[td("a", "d1"), td("p", "d1", pinned: true)]]), forKey: TodoStore.Keys.todos)
defaults.setValue(["d1"], forKey: TodoStore.Keys.dates)
let migrateStore = TodoStore(userDefaults: defaults)
migrateStore.load()
expect(migrateStore.pinnedDatas.map(\.todo) == ["p"]
    && migrateStore.todoDatas[0].map(\.todo) == ["a"],
    "load: 섹션 내 고정(구조 변경 전) 항목을 전역 고정으로 마이그레이션")

// MARK: 12. 일괄 아카이브 + isPinned 해제 확인
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")]])
store.batchArchive(at: [ip(0, 0), ip(1, 0)], dateString: "2026.07.19")
let archive = store.loadArchive()
expect(store.todoDatas.count == 1 && store.todoDatas[0].map(\.todo) == ["b"],
    "batchArchive: 원본에서 제거, 빈 섹션 정리")
expect(archive.dates == ["2026.07.19"] && archive.datas[0].map(\.todo) == ["a", "c"],
    "batchArchive: 아카이브 오늘 날짜 섹션에 추가")
store.appendToArchive([td("p", "d0", pinned: true)], dateString: "2026.07.19")
let archive2 = store.loadArchive()
expect(archive2.datas[0].last?.isPinned == false, "appendToArchive: isPinned 해제")

// MARK: 13. 일괄 삭제 (여러 섹션)
store = freshStore([[td("a", "d1"), td("b", "d1")], [td("c", "d2")], [td("d", "d3")]])
store.batchDelete(at: [ip(0, 1), ip(1, 0), ip(2, 0)])
expect(store.todoDatas.count == 1 && store.todoDatas[0].map(\.todo) == ["a"] && store.dateInfo == ["d1"],
    "batchDelete: 여러 섹션에 걸친 삭제 + 빈 섹션 정리")

// MARK: 14. dateInfo 불일치 자가 복구
defaults.removePersistentDomain(forName: suiteName)
defaults.set(try! PropertyListEncoder().encode([[td("a", "d1")], [td("b", "d2")]]), forKey: TodoStore.Keys.todos)
defaults.setValue(["d1"], forKey: TodoStore.Keys.dates)
let healStore = TodoStore(userDefaults: defaults)
healStore.load()
expect(healStore.dateInfo == ["d1", "d2"], "load: dateInfo 개수 불일치 시 데이터에서 재구성")

// MARK: 15. 저장/로드 라운드트립 (고정 목록 포함)
store = freshStore([[td("a", "d1", important: true)]], pinned: [td("p", "d0", pinned: true)])
store.save()
let reloaded = TodoStore(userDefaults: defaults)
reloaded.load()
expect(reloaded.pinnedDatas.map(\.todo) == ["p"]
    && reloaded.pinnedDatas[0].isPinned
    && reloaded.todoDatas[0][0].isImportant,
    "save/load 라운드트립: 고정 목록 유지")

defaults.removePersistentDomain(forName: suiteName)
print(failures == 0 ? "\nALL TESTS PASSED" : "\n\(failures) TEST(S) FAILED")
exit(failures == 0 ? 0 : 1)
