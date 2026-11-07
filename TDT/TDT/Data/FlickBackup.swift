//
//  FlickBackup.swift
//  TDT
//
//  백업 파일(JSON) 형식과 읽기/쓰기. 설정 값은 파일에 넣지 않는다.
//

import Foundation

struct BackupItem: Codable, Equatable {
    var date: String
    var todo: String
    var isImportant: Bool
}

struct BackupSection: Codable, Equatable {
    var date: String
    var items: [BackupItem]
}

struct BackupContent: Equatable {
    var todos: [BackupSection]
    var pinned: [BackupItem]
    var archive: [BackupSection]

    var isEmpty: Bool {
        todos.isEmpty && pinned.isEmpty && archive.isEmpty
    }
}

enum BackupError: Error, Equatable {
    case invalidFile
    case newerVersion
}

extension Notification.Name {
    /// 가져오기가 저장소를 바꾼 뒤 화면과 메모리 데이터를 다시 읽게 하는 알림
    static let flickDataDidImport = Notification.Name("flickDataDidImport")
}

enum FlickBackup {
    static let format = "flick-backup"
    static let currentVersion = 1

    private struct Header: Decodable {
        var format: String
        var version: Int
    }

    private struct Source: Codable {
        var platform: String
        var appVersion: String
    }

    private struct File: Codable {
        var format: String
        var version: Int
        var exportedAt: String
        var source: Source
        var todos: [BackupSection]
        var pinned: [BackupItem]
        var archive: [BackupSection]
    }

    private struct ReadFile: Decodable {
        var todos: [BackupSection]
        var pinned: [BackupItem]
        var archive: [BackupSection]
    }

    /// yyyy.MM.dd 모양인지 (달력상 유효한지는 보지 않는다)
    static func isValidDate(_ string: String) -> Bool {
        string.range(of: #"^[0-9]{4}\.[0-9]{2}\.[0-9]{2}\z"#, options: .regularExpression) != nil
    }

    /// 앞 10자를 ASCII 숫자로 바꿔 yyyy.MM.dd면 돌려준다.
    /// (아랍어·페르시아어 로케일의 DateFormatter는 ٢٠٢٦.١١.٠٧처럼 저장한다)
    static func asciiDay(_ string: String) -> String? {
        let head = String(string.prefix(10).map { c in
            c.wholeNumberValue.flatMap { (0...9).contains($0) ? Character(String($0)) : nil } ?? c
        })
        return isValidDate(head) ? head : nil
    }

    /// 내보내기 전에 옛 데이터를 정리한다: 날짜는 앞 10자(yyyy.MM.dd)로 맞추고,
    /// 공백뿐인 메모와 빈 섹션은 버리고, 같은 날짜 섹션은 합친다.
    static func sanitized(_ content: BackupContent, today: String) -> BackupContent {
        func day(_ string: String) -> String? { asciiDay(string) }
        func cleanItems(_ items: [BackupItem], fallback: String) -> [BackupItem] {
            items.compactMap { item in
                guard !item.todo.isBlank else { return nil }
                var copy = item
                copy.date = day(item.date) ?? fallback
                return copy
            }
        }
        func cleanSections(_ sections: [BackupSection], ascending: Bool) -> [BackupSection] {
            var result: [BackupSection] = []
            for section in sections {
                let date = day(section.date) ?? section.items.first.flatMap { day($0.date) } ?? today
                let items = cleanItems(section.items, fallback: date)
                guard !items.isEmpty else { continue }
                if let index = result.firstIndex(where: { $0.date == date }) {
                    result[index].items += items
                } else {
                    result.append(BackupSection(date: date, items: items))
                }
            }
            // 날짜는 서로 달라 정렬이 곧 안정 정렬이다
            return result.sorted { ascending ? $0.date < $1.date : $0.date > $1.date }
        }
        return BackupContent(
            todos: cleanSections(content.todos, ascending: true),
            pinned: cleanItems(content.pinned, fallback: today),
            archive: cleanSections(content.archive, ascending: false)
        )
    }

    static func exportData(content: BackupContent, appVersion: String, now: Date) throws -> Data {
        let file = File(
            format: format,
            version: currentVersion,
            exportedAt: ISO8601DateFormatter().string(from: now),
            source: Source(platform: "ios", appVersion: appVersion),
            todos: content.todos,
            pinned: content.pinned,
            archive: content.archive
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(file)
    }

    static func parse(_ data: Data) throws -> BackupContent {
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(Header.self, from: data),
              header.format == format, header.version >= 1
        else { throw BackupError.invalidFile }
        guard header.version <= currentVersion else { throw BackupError.newerVersion }

        guard let file = try? decoder.decode(ReadFile.self, from: data) else {
            throw BackupError.invalidFile
        }
        guard (file.todos + file.archive).allSatisfy(isValid(section:)),
              file.pinned.allSatisfy(isValid(item:))
        else { throw BackupError.invalidFile }

        return BackupContent(todos: file.todos, pinned: file.pinned, archive: file.archive)
    }

    static func fileName(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "flick-backup-\(formatter.string(from: now)).json"
    }

    private static func isValid(section: BackupSection) -> Bool {
        isValidDate(section.date) && section.items.allSatisfy(isValid(item:))
    }

    private static func isValid(item: BackupItem) -> Bool {
        isValidDate(item.date) && !item.todo.isBlank
    }
}
