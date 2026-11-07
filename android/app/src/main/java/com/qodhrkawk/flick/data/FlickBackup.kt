package com.qodhrkawk.flick.data

import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.intOrNull

/**
 * iOS `FlickBackup.swift` 포팅 — 백업 파일(JSON) 형식과 읽기/쓰기.
 * 설계: docs/superpowers/specs/2026-11-07-flick-3.1-data-transfer-design.md (feature/3.1)
 * 설정 값과 안드로이드 내부 id는 파일에 넣지 않는다.
 */
@Serializable
data class BackupItem(val date: String, val todo: String, val isImportant: Boolean)

@Serializable
data class BackupSection(val date: String, val items: List<BackupItem>)

data class BackupContent(
    val todos: List<BackupSection>,
    val pinned: List<BackupItem>,
    val archive: List<BackupSection>,
) {
    val isEmpty: Boolean get() = todos.isEmpty() && pinned.isEmpty() && archive.isEmpty()
}

sealed class BackupException : Exception() {
    /** 형식이 틀린 파일: "Flick 데이터 파일이 아니에요" */
    class InvalidFile : BackupException()

    /** 앱보다 새 버전의 파일: "앱을 업데이트한 뒤 다시 가져와 주세요" */
    class NewerVersion : BackupException()
}

object FlickBackup {
    const val FORMAT = "flick-backup"
    const val CURRENT_VERSION = 1

    private val readJson = Json { ignoreUnknownKeys = true }
    private val writeJson = Json { prettyPrint = true }
    private val dateShape = Regex("[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}")

    @Serializable
    private data class Source(val platform: String, val appVersion: String)

    @Serializable
    private data class File(
        val format: String,
        val version: Int,
        val exportedAt: String,
        val source: Source,
        val todos: List<BackupSection>,
        val pinned: List<BackupItem>,
        val archive: List<BackupSection>,
    )

    @Serializable
    private data class ReadFile(
        val todos: List<BackupSection>,
        val pinned: List<BackupItem>,
        val archive: List<BackupSection>,
    )

    /** yyyy.MM.dd 모양인지 (달력상 유효한지는 보지 않는다) */
    fun isValidDate(string: String): Boolean = dateShape.matches(string)

    /**
     * 내보내기 전에 옛 데이터를 정리한다: 날짜는 앞 10자(yyyy.MM.dd)로 맞추고,
     * 공백뿐인 메모와 빈 섹션은 버리고, 같은 날짜 섹션은 합친다.
     */
    fun sanitized(content: BackupContent, today: String): BackupContent {
        fun day(string: String): String? = string.take(10).takeIf(::isValidDate)

        fun cleanItems(items: List<BackupItem>, fallback: String): List<BackupItem> =
            items.mapNotNull { item ->
                if (item.todo.isBlank()) null else item.copy(date = day(item.date) ?: fallback)
            }

        fun cleanSections(sections: List<BackupSection>, ascending: Boolean): List<BackupSection> {
            val result = mutableListOf<BackupSection>()
            for (section in sections) {
                val date = day(section.date)
                    ?: section.items.firstOrNull()?.let { day(it.date) }
                    ?: today
                val items = cleanItems(section.items, date)
                if (items.isEmpty()) continue
                val index = result.indexOfFirst { it.date == date }
                if (index != -1) {
                    result[index] = result[index].copy(items = result[index].items + items)
                } else {
                    result.add(BackupSection(date, items))
                }
            }
            return if (ascending) result.sortedBy { it.date } else result.sortedByDescending { it.date }
        }

        return BackupContent(
            todos = cleanSections(content.todos, ascending = true),
            pinned = cleanItems(content.pinned, today),
            archive = cleanSections(content.archive, ascending = false),
        )
    }

    fun exportJson(content: BackupContent, appVersion: String, now: Instant): String =
        writeJson.encodeToString(
            File(
                format = FORMAT,
                version = CURRENT_VERSION,
                exportedAt = DateTimeFormatter.ISO_INSTANT.format(now.truncatedTo(ChronoUnit.SECONDS)),
                source = Source(platform = "android", appVersion = appVersion),
                todos = content.todos,
                pinned = content.pinned,
                archive = content.archive,
            )
        )

    /** 파일 전체를 검증한다. 하나라도 틀리면 전체를 거절해 일부만 가져오는 일이 없게 한다 */
    fun parse(text: String): BackupContent {
        val root = runCatching { readJson.parseToJsonElement(text) as? JsonObject }.getOrNull()
            ?: throw BackupException.InvalidFile()
        val format = (root["format"] as? JsonPrimitive)?.takeIf { it.isString }?.content
        val version = (root["version"] as? JsonPrimitive)?.takeIf { !it.isString }?.intOrNull
        if (format != FORMAT || version == null || version < 1) throw BackupException.InvalidFile()
        if (version > CURRENT_VERSION) throw BackupException.NewerVersion()

        // kotlinx는 "true" 같은 따옴표 친 불리언도 받아 주므로, iOS Codable처럼 값의 타입을 먼저 확인한다
        if (!hasStrictTypes(root)) throw BackupException.InvalidFile()
        val file = runCatching { readJson.decodeFromString<ReadFile>(text) }.getOrNull()
            ?: throw BackupException.InvalidFile()
        val valid = (file.todos + file.archive).all(::isValidSection) && file.pinned.all(::isValidItem)
        if (!valid) throw BackupException.InvalidFile()

        return BackupContent(todos = file.todos, pinned = file.pinned, archive = file.archive)
    }

    fun fileName(today: LocalDate): String =
        "flick-backup-${today.format(DateTimeFormatter.ISO_LOCAL_DATE)}.json"

    private fun hasStrictTypes(root: JsonObject): Boolean {
        fun isString(element: JsonElement?) = (element as? JsonPrimitive)?.isString == true
        fun isItem(element: JsonElement): Boolean {
            val item = element as? JsonObject ?: return false
            val important = item["isImportant"] as? JsonPrimitive ?: return false
            return isString(item["date"]) && isString(item["todo"]) && !important.isString && important.booleanOrNull != null
        }
        fun isSection(element: JsonElement): Boolean {
            val section = element as? JsonObject ?: return false
            val items = section["items"] as? JsonArray ?: return false
            return isString(section["date"]) && items.all(::isItem)
        }
        val todos = root["todos"] as? JsonArray ?: return false
        val pinned = root["pinned"] as? JsonArray ?: return false
        val archive = root["archive"] as? JsonArray ?: return false
        return todos.all(::isSection) && pinned.all(::isItem) && archive.all(::isSection)
    }

    private fun isValidSection(section: BackupSection): Boolean =
        isValidDate(section.date) && section.items.all(::isValidItem)

    private fun isValidItem(item: BackupItem): Boolean =
        isValidDate(item.date) && !item.todo.isBlank()
}
