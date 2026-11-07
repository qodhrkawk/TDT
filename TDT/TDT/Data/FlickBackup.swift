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
        string.range(of: #"^\d{4}\.\d{2}\.\d{2}$"#, options: .regularExpression) != nil
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
