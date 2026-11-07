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

expect(FlickBackup.isValidDate("2026.11.07"), "isValidDate: 정상")
expect(!FlickBackup.isValidDate("2026.11.07\n"), "isValidDate: 끝 줄바꿈 거절")
expect(!FlickBackup.isValidDate("٢٠٢٦.١١.٠٧"), "isValidDate: 아라비아 숫자 거절")

// MARK: 17. 내보내기 정리
func bi(_ text: String, _ date: String, important: Bool = false) -> BackupItem {
    BackupItem(date: date, todo: text, isImportant: important)
}
func bs(_ date: String, _ items: [BackupItem]) -> BackupSection { BackupSection(date: date, items: items) }

let dirty = BackupContent(
    todos: [
        bs("2021.01.25 10:30", [bi("옛 날짜", "2021.01.25 10:30"), bi(" \n", "2021.01.25 10:30")]),
        bs("2021.01.25", [bi("같은 날", "2021.01.25")]),
        bs("", [bi("섹션 날짜 없음", "2021.02.01")]),
        bs("", [bi("날짜 모두 없음", "")]),
        bs("2021.03.01", [bi("", "2021.03.01")])
    ],
    pinned: [bi("고정", "2021.01.25 10:30"), bi("   ", "2021.01.25")],
    archive: [bs("2021.01.26", [bi("작년 완료", "2021.01.25 10:30")]), bs("2021.02.26", [bi("최근 완료", "2021.02.25")])]
)
let clean = FlickBackup.sanitized(dirty, today: "2026.11.07")
expect(clean.todos.map(\.date) == ["2021.01.25", "2021.02.01", "2026.11.07"], "sanitize: 날짜 정리, 합치기, 오름차순")
expect(clean.todos[0].items.map(\.todo) == ["옛 날짜", "같은 날"], "sanitize: 공백 메모 제외, 순서 유지")
expect(clean.todos[2].items[0].date == "2026.11.07", "sanitize: 날짜 없으면 오늘")
expect(clean.pinned.map(\.date) == ["2021.01.25"], "sanitize: 고정도 정리")
expect(clean.archive.map(\.date) == ["2021.02.26", "2021.01.26"], "sanitize: 아카이브 내림차순")
expect(clean.archive[1].items[0].date == "2021.01.25", "sanitize: 아카이브 항목 날짜 정리")
expect(FlickBackup.sanitized(BackupContent(todos: [bs("2021.03.01", [bi("", "2021.03.01")])], pinned: [], archive: []), today: "2026.11.07").isEmpty,
       "sanitize: 공백 메모만 있으면 비어 있음")

// MARK: 16. 백업 파일
let fixture = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let parsed = try! FlickBackup.parse(fixture)
expect(parsed.todos.map(\.date) == ["2026.11.06", "2026.11.07"], "backup: 섹션 순서 유지")
expect(parsed.todos[0].items.count == 2, "backup: 같은 날 같은 메모 보존")
expect(parsed.todos[1].items[0].todo == "첫 줄\n둘째 줄 \"인용\" \\ 끝", "backup: 특수문자 내용 보존")
expect(parsed.todos[1].items[0].isImportant, "backup: 중요 표시 보존")
expect(parsed.pinned.map(\.todo) == ["고정 메모"], "backup: 고정 읽기")
expect(parsed.archive[0].date == "2026.11.06" && parsed.archive[0].items[0].date == "2026.11.02",
       "backup: 완료 날짜와 작성 날짜 구분")

let now = Date(timeIntervalSince1970: 1_794_000_000)
var emojiContent = parsed
emojiContent.todos[0].items[0].todo = "이모지 \u{1F600} 포함"
let exported = try! FlickBackup.exportData(content: emojiContent, appVersion: "3.1.0", now: now)
expect(try! FlickBackup.parse(exported) == emojiContent, "backup: 내보내고 다시 읽으면 같다")
let header = try! JSONSerialization.jsonObject(with: exported) as! [String: Any]
expect(header["format"] as? String == "flick-backup" && header["version"] as? Int == 1, "backup: 헤더 값")
expect((header["source"] as? [String: String])?["platform"] == "ios", "backup: 플랫폼 표시")

func parseError(_ json: String) -> BackupError? {
    do { _ = try FlickBackup.parse(Data(json.utf8)); return nil }
    catch { return error as? BackupError }
}
let goodTail = "\"exportedAt\":\"x\",\"source\":{\"platform\":\"ios\",\"appVersion\":\"3.1.0\"}"
func file(todos: String) -> String {
    "{\"format\":\"flick-backup\",\"version\":1,\(goodTail),\"todos\":\(todos),\"pinned\":[],\"archive\":[]}"
}
expect(parseError("not json") == .invalidFile, "backup: JSON 아님 거절")
expect(parseError("{\"format\":\"other\",\"version\":1}") == .invalidFile, "backup: 다른 format 거절")
expect(parseError("{\"format\":\"flick-backup\",\"version\":2}") == .newerVersion, "backup: 새 버전 거절")
expect(parseError(file(todos: "[{\"date\":\"2026-11-07\",\"items\":[]}]")) == .invalidFile, "backup: 날짜 형식 거절")
expect(parseError(file(todos: "[{\"date\":\"2026.11.07\",\"items\":[{\"date\":\"2026.11.07\",\"todo\":\" \\n\",\"isImportant\":false}]}]")) == .invalidFile,
       "backup: 공백뿐인 메모 거절")
expect(FlickBackup.fileName(now: now).hasPrefix("flick-backup-") && FlickBackup.fileName(now: now).hasSuffix(".json"), "backup: 파일 이름")
expect(" \n\t".isBlank && !" a ".isBlank, "String.isBlank")

// MARK: 18. 합치기
let d = "2026.11.07"
let guides = BackupMerger.guideTexts.map { bi($0, d) }
let empty = BackupContent(todos: [], pinned: [], archive: [])

var m = BackupMerger.merge(
    current: BackupContent(todos: [bs("2026.11.05", [bi("a", "2026.11.05")]), bs(d, [bi("b", d)])], pinned: [], archive: []),
    incoming: BackupContent(todos: [bs("2026.11.06", [bi("c", "2026.11.06")]), bs(d, [bi("b", d), bi("d", d)])], pinned: [], archive: []),
    today: d
)
expect(m.added == 2 && m.skipped == 1, "merge: 추가와 건너뜀 개수")
expect(m.merged.todos.map(\.date) == ["2026.11.05", "2026.11.06", d], "merge: 날짜 오름차순 삽입")
expect(m.merged.todos[2].items.map(\.todo) == ["b", "d"], "merge: 기존 항목 뒤에 추가")

m = BackupMerger.merge(
    current: BackupContent(todos: [bs(d, [bi("운동", d)])], pinned: [], archive: []),
    incoming: BackupContent(todos: [bs(d, [bi("운동", d), bi("운동", d)])], pinned: [], archive: []),
    today: d
)
expect(m.added == 1 && m.skipped == 1, "merge: a-b개만 추가")
let again = BackupMerger.merge(current: m.merged, incoming: BackupContent(todos: [bs(d, [bi("운동", d), bi("운동", d)])], pinned: [], archive: []), today: d)
expect(again.added == 0 && again.skipped == 2, "merge: 다시 가져와도 늘지 않음")

m = BackupMerger.merge(
    current: BackupContent(todos: [bs(d, [bi("x", d, important: false)])], pinned: [bi("p", "2026.11.01")], archive: []),
    incoming: BackupContent(todos: [bs("2026.11.01", [bi("p", "2026.11.01")])], pinned: [bi("x", d), bi("q", d, important: true), bi("r", d)], archive: []),
    today: d
)
expect(m.added == 2 && m.skipped == 2, "merge: 일반과 고정은 한 묶음으로 비교")
expect(m.merged.pinned.map(\.todo) == ["p", "q", "r"], "merge: 새 고정은 기존 뒤에 파일 순서로")
expect(m.merged.todos[0].items[0].isImportant == false, "merge: 기존 상태 유지")

m = BackupMerger.merge(
    current: BackupContent(todos: [bs(d, [bi("t", d)])], pinned: [], archive: [bs("2026.11.05", [bi("old", "2026.11.01")])]),
    incoming: BackupContent(todos: [], pinned: [], archive: [
        bs("2026.11.06", [bi("t", d)]),
        bs("2026.11.05", [bi("old", "2026.11.01"), bi("old", "2026.10.01")]),
        bs("2026.11.04", [bi("older", "2026.11.01")])
    ]),
    today: d
)
expect(m.merged.archive.map(\.date) == ["2026.11.06", "2026.11.05", "2026.11.04"], "merge: 아카이브 내림차순 삽입")
expect(m.merged.archive[1].items.map(\.date) == ["2026.11.01", "2026.10.01"], "merge: 아카이브는 완료+작성 날짜로 비교")
expect(m.added == 3 && m.skipped == 1, "merge: 일반과 아카이브는 따로 비교")

m = BackupMerger.merge(
    current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []),
    incoming: BackupContent(todos: [bs("2026.11.01", [bi("진짜", "2026.11.01")])], pinned: [], archive: []),
    today: d
)
expect(m.merged.todos.map(\.date) == ["2026.11.01"] && m.added == 1, "merge: 기기 안내 세트 제거")

let onlyGuides = BackupContent(todos: [bs("2026.11.01", BackupMerger.guideTexts.map { bi($0, "2026.11.01") })], pinned: [], archive: [])
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []), incoming: onlyGuides, today: d)
expect(m.added == 0 && m.skipped == 0 && m.merged.todos.map(\.date) == [d], "merge: 안내 세트만 있으면 변화 없음")

m = BackupMerger.merge(
    current: BackupContent(todos: [bs(d, Array(guides.prefix(2)))], pinned: [], archive: []),
    incoming: BackupContent(todos: [bs("2026.11.01", [bi("진짜", "2026.11.01")])], pinned: [], archive: []),
    today: d
)
expect(m.merged.todos.count == 2, "merge: 손댄 안내 항목은 유지")

let withGuide = BackupContent(todos: [bs("2026.11.01", BackupMerger.guideTexts.map { bi($0, "2026.11.01") } + [bi("진짜", "2026.11.01")])], pinned: [], archive: [])
m = BackupMerger.merge(current: empty, incoming: withGuide, today: d)
expect(m.merged.todos[0].items.map(\.todo) == ["진짜"] && m.added == 1, "merge: 파일 안내 세트는 가져오지 않음")

let legacyDates = BackupContent(todos: [bs("2021.01.25 10:30", [bi("옛 메모", "2021.01.25 10:30")])], pinned: [], archive: [])
m = BackupMerger.merge(current: legacyDates, incoming: FlickBackup.sanitized(legacyDates, today: d), today: d)
expect(m.added == 0 && m.skipped == 1, "merge: 옛 날짜가 남은 기기에서 자기 파일 재가져오기")

let bigItems = (0..<5000).map { bi("메모 \($0)", d) }
let started = Date()
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, bigItems)], pinned: [], archive: []),
                       incoming: BackupContent(todos: [bs(d, bigItems)], pinned: [], archive: []), today: d)
expect(m.added == 0 && Date().timeIntervalSince(started) < 1, "merge: 5000개를 1초 안에")

// 5000개 섹션을 빈 기기로 (새 날짜가 많아도 느려지지 않아야 한다)
let manyDates = (0..<5000).map { i -> String in
    let month = i / 28 % 12 + 1, day = i % 28 + 1, year = 2000 + i / 336
    return String(format: "%04d.%02d.%02d", year, month, day)
}
let manyTodos = manyDates.reversed().map { bs($0, [bi("메모 \($0)", $0)]) }
let startedSections = Date()
m = BackupMerger.merge(current: empty, incoming: BackupContent(todos: manyTodos, pinned: [], archive: []), today: d)
expect(m.added == 5000 && Date().timeIntervalSince(startedSections) < 1, "merge: 섹션 5000개 할 일을 1초 안에")
expect(m.merged.todos.map(\.date) == manyDates.sorted(), "merge: 섹션 5000개 오름차순")
let startedArchive = Date()
m = BackupMerger.merge(current: empty, incoming: BackupContent(todos: [], pinned: [], archive: manyTodos), today: d)
expect(m.added == 5000 && Date().timeIntervalSince(startedArchive) < 1, "merge: 섹션 5000개 아카이브를 1초 안에")
expect(m.merged.archive.map(\.date) == manyDates.sorted(by: >), "merge: 섹션 5000개 내림차순")

// 기기에 옛 값이 남은 채 자기 파일을 다시 가져와도 늘지 않는다
m = BackupMerger.merge(current: dirty, incoming: FlickBackup.sanitized(dirty, today: d), today: d)
expect(m.added == 0 && m.merged == dirty, "merge: 정리 전 기기 데이터의 자기 파일 재가져오기")
let odd = BackupContent(
    todos: [bs("2021.03.01", [bi("빈 날짜", ""), bi("슬래시", "2021/03/02")])],
    pinned: [bi("고정 빈 날짜", "")],
    archive: [bs("2021.04.01", [bi("완료 빈 날짜", "")]), bs("x", [bi("섹션 날짜 불가", "2021.01.01")])]
)
m = BackupMerger.merge(current: odd, incoming: FlickBackup.sanitized(odd, today: d), today: d)
expect(m.added == 0 && m.skipped == 5 && m.merged == odd, "merge: 날짜가 비었거나 읽을 수 없는 항목도 늘지 않음")

// 안내 세트 판정
let g1 = BackupMerger.guideTexts[0], g2 = BackupMerger.guideTexts[1], g3 = BackupMerger.guideTexts[2]
let real = bi("진짜", "2026.11.01")
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, [bi(g1, d), bi(g2, d, important: true), bi(g3, d)])], pinned: [], archive: []),
                       incoming: BackupContent(todos: [bs("2026.11.01", [real])], pinned: [], archive: []), today: d)
expect(m.merged.todos.count == 2 && m.merged.todos[1].items.count == 3, "merge: 중요 표시한 안내 항목은 손댄 것으로 봄")
let importantFile = BackupContent(todos: [bs("2026.11.01", [bi(g1, "2026.11.01"), bi(g2, "2026.11.01", important: true), bi(g3, "2026.11.01")])], pinned: [], archive: [])
m = BackupMerger.merge(current: empty, incoming: importantFile, today: d)
expect(m.added == 3, "merge: 파일의 중요 표시한 안내 항목은 가져옴")
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, [bi(g1, d), bi(g2, d), bi(g3, "2026.11.01")])], pinned: [], archive: []),
                       incoming: BackupContent(todos: [bs("2026.11.01", [real])], pinned: [], archive: []), today: d)
expect(m.merged.todos.count == 2, "merge: 날짜가 다른 안내 항목은 세트가 아님")

// 기기에 g1만, 파일에 g2 g3
let partialDevice = BackupContent(todos: [bs(d, [bi(g1, d)])], pinned: [], archive: [])
let partialFile = BackupContent(todos: [bs(d, [bi(g2, d), bi(g3, d)])], pinned: [], archive: [])
m = BackupMerger.merge(current: partialDevice, incoming: partialFile, today: d)
expect(m.added == 2 && m.merged.todos[0].items.map(\.todo) == [g1, g2, g3], "merge: 흩어진 안내 문구는 세트가 아님")

// 빈 기기에 안내 세트 두 벌
let doubleSet = BackupContent(todos: [bs("2026.11.01", BackupMerger.guideTexts.map { bi($0, "2026.11.01") } + BackupMerger.guideTexts.map { bi($0, "2026.11.01") })], pinned: [], archive: [])
m = BackupMerger.merge(current: empty, incoming: doubleSet, today: d)
expect(m.added == 0 && m.skipped == 0 && m.merged.isEmpty, "merge: 안내 세트 두 벌은 모두 가져오지 않음")

// 기기 안내 세트가 다른 날짜에 있고 파일에 두 벌: 아무것도 바뀌지 않는다
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []), incoming: doubleSet, today: d)
expect(m.added == 0 && m.merged.todos == [bs(d, guides)], "merge: 파일에 안내 세트만 두 벌이면 기기 그대로")
// 두 벌에 진짜 항목이 섞인 경우
let doubleSetReal = BackupContent(todos: [bs("2026.11.01", doubleSet.todos[0].items + [real])], pinned: [], archive: [])
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []), incoming: doubleSetReal, today: d)
expect(m.merged.todos.map(\.date) == ["2026.11.01"] && m.added == 1, "merge: 기기 세트는 지우고 새로 들어온 항목은 남김")
let afterLater = BackupMerger.merge(current: m.merged, incoming: doubleSetReal, today: d)
expect(afterLater.added == 0, "merge: 다른 날짜 기기 세트 뒤 다시 가져와도 늘지 않음")

// 기기 안내 세트와 같은 날짜의 파일 항목
let guideAndReal = BackupContent(todos: [bs(d, [bi(g1, d), bi(g2, d), bi("진짜", d)])], pinned: [], archive: [])
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []), incoming: guideAndReal, today: d)
expect(m.added == 3 && m.skipped == 0 && m.merged.todos[0].items.map(\.todo) == [g1, g2, "진짜"], "merge: 기기 안내 항목이 파일 항목을 흡수하지 않음")
let afterGuideAndReal = BackupMerger.merge(current: m.merged, incoming: guideAndReal, today: d)
expect(afterGuideAndReal.added == 0 && afterGuideAndReal.skipped == 3, "merge: 같은 파일 다시 가져오면 0개")
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []),
                       incoming: BackupContent(todos: [bs(d, [bi("진짜", d)])], pinned: [], archive: []), today: d)
expect(m.merged.todos.count == 1 && m.merged.todos[0].items.map(\.todo) == ["진짜"], "merge: 기기 안내 섹션에 들어온 새 항목은 남음")
m = BackupMerger.merge(current: BackupContent(todos: [bs(d, guides)], pinned: [], archive: []), incoming: empty, today: d)
expect(m.added == 0 && m.merged.todos == [bs(d, guides)], "merge: 추가가 없으면 기기 데이터 그대로")

// MARK: 19. 스토어 백업 연결
store = freshStore([[td("a", "2026.11.06", important: true)]], pinned: [td("p", "2026.11.01", pinned: true)])
store.appendToArchive([td("done", "2026.11.02")], dateString: "2026.11.05")
let snapshot = store.backupContent()
expect(snapshot.todos == [bs("2026.11.06", [bi("a", "2026.11.06", important: true)])], "store: 할 일 내보내기")
expect(snapshot.pinned == [bi("p", "2026.11.01")], "store: 고정 내보내기")
expect(snapshot.archive == [bs("2026.11.05", [bi("done", "2026.11.02")])], "store: 아카이브 내보내기")

let replacement = BackupContent(
    todos: [bs("2026.11.07", [bi("new", "2026.11.07")])],
    pinned: [bi("np", "2026.11.03")],
    archive: [bs("2026.11.04", [bi("nd", "2026.11.03")])]
)
store.replaceAll(with: replacement)
let other = TodoStore(userDefaults: defaults)
other.load()
expect(other.backupContent() == replacement, "store: 다른 인스턴스가 다시 읽으면 합친 결과가 보인다")
expect(other.pinnedDatas[0].isPinned, "store: 고정 표시 복원")
expect(other.dateInfo == ["2026.11.07"], "store: dateInfo 동기화")

// MARK: 20. 아라비아-인도 숫자 날짜 (ar_EG 등 로케일의 DateFormatter 결과)
func arabic(_ ascii: String) -> String {
    String(ascii.map { c in
        guard let v = c.wholeNumberValue, c.isASCII else { return c }
        return Character(UnicodeScalar(0x0660 + v)!)
    })
}
let d1 = "2026.11.05"
let d2 = "2026.11.07"
let arabicDevice = BackupContent(
    todos: [bs(arabic("2026.11.01"), [bi("a", arabic("2026.11.01"))]),
            bs(arabic(d1), [bi("b", arabic("2026.10.30")), bi("c", arabic(d1))])],
    pinned: [bi("p", arabic("2026.10.20"))],
    archive: [bs(arabic("2026.11.04"), [bi("done", arabic("2026.11.02"))])]
)
let arabicClean = FlickBackup.sanitized(arabicDevice, today: d1)
expect(arabicClean.todos == [bs("2026.11.01", [bi("a", "2026.11.01")]),
                             bs(d1, [bi("b", "2026.10.30"), bi("c", d1)])], "arabic: 할 일 날짜를 ASCII로, 항목 날짜 유지")
expect(arabicClean.pinned == [bi("p", "2026.10.20")], "arabic: 고정 날짜를 ASCII로")
expect(arabicClean.archive == [bs("2026.11.04", [bi("done", "2026.11.02")])], "arabic: 아카이브 날짜를 ASCII로")
m = BackupMerger.merge(current: arabicDevice, incoming: arabicClean, today: d2)
expect(m.added == 0 && m.skipped == 5, "arabic: 다른 날 내 파일을 다시 가져와도 0개")
m = BackupMerger.merge(current: arabicDevice,
                       incoming: BackupContent(todos: [bs(d1, [bi("new", d1)])], pinned: [], archive: [bs("2026.11.04", [bi("new2", "2026.11.03")])]),
                       today: d2)
expect(m.added == 2 && m.merged.todos.count == 2 && m.merged.todos[1].items.map(\.todo) == ["b", "c", "new"],
       "arabic: 같은 날짜 할 일 섹션에 붙음")
expect(m.merged.archive.count == 1 && m.merged.archive[0].items.map(\.todo) == ["done", "new2"],
       "arabic: 같은 날짜 아카이브 섹션에 붙음")

// MARK: 21. 링크 인식 — ASCII까지만, 뒤에 붙은 한글 조사와 문장 부호는 제외 (Android LinkDetector와 같은 규칙)
func linkTexts(_ text: String) -> [String] {
    text.containedLinks.map { (text as NSString).substring(with: $0.range) }
}
func linkURLs(_ text: String) -> [String] {
    text.containedLinks.map(\.url.absoluteString)
}
expect(linkTexts("자세한 건 https://example.com에서 확인") == ["https://example.com"]
    && linkURLs("자세한 건 https://example.com에서 확인") == ["https://example.com"],
    "link: 도메인 뒤 조사 제외")
expect(linkTexts("naver.com에서 봐") == ["naver.com"] && linkURLs("naver.com에서 봐") == ["http://naver.com"],
       "link: scheme 없는 주소도 조사 제외")
expect(linkTexts("https://a.com/b에서") == ["https://a.com/b"] && linkURLs("https://a.com/b에서") == ["https://a.com/b"],
       "link: 경로 뒤 조사 제외")
expect(linkTexts("(https://a.com)에서") == ["https://a.com"], "link: 짝 없는 닫는 괄호 제외")
expect(linkTexts("https://a.com/x(1)") == ["https://a.com/x(1)"], "link: 짝 있는 괄호는 유지")
expect(linkTexts("https://a.com, 그리고") == ["https://a.com"], "link: 끝 문장 부호 제외")
expect(linkTexts("링크 https://a.com/path?x=1 참고") == ["https://a.com/path?x=1"], "link: 공백으로 끝나는 주소 그대로")
expect(linkURLs("HTTPS://A.com") == ["https://A.com"], "link: scheme 소문자")
expect(linkTexts("메일 a@b.com 으로").isEmpty, "link: 이메일은 링크 아님")

// MARK: 22. Android 앱이 내보낸 파일 가져오기
// fixtures/flick-backup-android-v1.json: Android TodoStore + FlickBackup.sanitized/exportJson으로 만든 실제 출력
let androidFile = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
let androidContent = try! FlickBackup.parse(androidFile)
expect(androidContent.todos.map(\.date) == ["2026.11.05", "2026.11.06", "2026.11.07"], "android: 섹션 날짜와 순서")
expect(androidContent.todos[0].items.map(\.todo) == ["안드로이드 운동", "안드로이드 운동"], "android: 같은 날 중복 메모")
expect(androidContent.todos[1].items[0].todo == "첫 줄\n둘째 줄 \"따옴표\" \\ 역슬래시 / 슬래시", "android: 특수문자 내용")
expect(androidContent.todos[1].items[1].todo == "이모지 \u{1F600} 와 링크 https://example.com에서 확인", "android: 이모지")
expect(androidContent.todos[2].items.last?.isImportant == true, "android: 중요 표시")
expect(androidContent.pinned == [bi("고정할 안드로이드 메모", "2026.11.04")], "android: 고정과 원래 날짜")
expect(androidContent.archive == [bs("2026.11.03", [bi("안드로이드에서 완료한 일", "2026.11.01", important: true)])],
       "android: 아카이브 완료·작성 날짜")

let androidToday = "2026.11.07"
defaults.removePersistentDomain(forName: suiteName)
let freshIPhone = TodoStore(userDefaults: defaults)
freshIPhone.load()
BackupMerger.guideTexts.forEach { freshIPhone.add(todo: $0, dateString: androidToday) }
let androidMerge = BackupMerger.merge(current: freshIPhone.backupContent(), incoming: androidContent, today: androidToday)
expect(androidMerge.added == 7 && androidMerge.skipped == 0, "android: 새 iPhone에 7개 추가")
expect(!androidMerge.merged.todos.flatMap(\.items).contains { BackupMerger.guideTexts.contains($0.todo) },
       "android: 기기·파일 안내 세트 모두 제외")
expect(androidMerge.merged.todos.last?.items.map(\.todo) == ["중요한 안드로이드 메모"], "android: 오늘 섹션에 실제 메모만")

freshIPhone.replaceAll(with: androidMerge.merged)
let androidReloaded = TodoStore(userDefaults: defaults)
androidReloaded.load()
expect(androidReloaded.backupContent() == androidMerge.merged, "android: 저장 후 다시 읽어도 같음")
expect(BackupMerger.merge(current: androidReloaded.backupContent(), incoming: androidContent, today: androidToday).added == 0,
       "android: 같은 파일 다시 가져와도 늘지 않음")
expect(androidContent.todos[1].items[1].todo.firstContainedURL?.absoluteString == "https://example.com",
       "android: 가져온 메모의 링크")

defaults.removePersistentDomain(forName: suiteName)
print(failures == 0 ? "\nALL TESTS PASSED" : "\n\(failures) TEST(S) FAILED")
exit(failures == 0 ? 0 : 1)
