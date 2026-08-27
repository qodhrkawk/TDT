package com.qodhrkawk.flick.data

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * iOS `TDT/TDT/Data/TodoStore.swift` 포팅.
 * 할 일 데이터의 변형과 영속화를 담당한다. UI 의존이 없어 단독으로 테스트 가능하다.
 *
 * - 리스트는 날짜 섹션만 표시한다. public API의 Position은 날짜 섹션 좌표계다.
 * - 고정(pin)은 날짜와 무관한 전역 목록(pinnedDatas)으로, 스티키 바에 표시된다.
 *   고정 해제하면 항목의 원래 날짜 섹션으로 돌아간다.
 */
class TodoStore(private val storage: KeyValueStore) {
    object Keys {
        const val TODOS = "TodoDatas"
        const val DATES = "dates"
        const val PINNED = "PinnedTodoDatas"
        const val ARCHIVE_TODOS = "ArchiveDatas"
        const val ARCHIVE_DATES = "ArchiveDates"
    }

    private val json = Json { ignoreUnknownKeys = true }

    private var sections: MutableList<MutableList<TodoData>> = mutableListOf()
    private var dates: MutableList<String> = mutableListOf()
    private var pinned: MutableList<TodoData> = mutableListOf()

    val todoDatas: List<List<TodoData>> get() = sections
    val dateInfo: List<String> get() = dates
    val pinnedDatas: List<TodoData> get() = pinned

    val isEmpty: Boolean get() = sections.isEmpty()

    fun todoAt(position: Position): TodoData? =
        sections.getOrNull(position.section)?.getOrNull(position.row)

    // 로드 / 저장

    fun load() {
        sections = decodeSections(storage.getString(Keys.TODOS))
        dates = decodeDates(storage.getString(Keys.DATES))
        if (dates.size != sections.size) {
            dates = sections.map { it.firstOrNull()?.date ?: "" }.toMutableList()
        }
        pinned = storage.getString(Keys.PINNED)
            ?.let { runCatching { json.decodeFromString<List<TodoData>>(it) }.getOrNull() }
            .orEmpty()
            .toMutableList()

        migrateScatteredPinsIfNeeded()
    }

    /** 과거 구현(섹션 내 고정)이 날짜 섹션 안에 남긴 isPinned 항목을 전역 고정으로 승격 */
    private fun migrateScatteredPinsIfNeeded() {
        val scattered = mutableListOf<TodoData>()
        for (section in sections) {
            val pins = section.filter { it.isPinned }
            if (pins.isEmpty()) continue
            scattered.addAll(pins)
            section.removeAll { it.isPinned }
        }
        if (scattered.isEmpty()) return

        pinned.addAll(0, scattered)
        removeEmptyDateSections()
        save()
    }

    fun save() {
        storage.putString(Keys.TODOS, json.encodeToString<List<List<TodoData>>>(sections))
        storage.putString(Keys.DATES, json.encodeToString<List<String>>(dates))
        storage.putString(Keys.PINNED, json.encodeToString<List<TodoData>>(pinned))
    }

    // 추가 / 수정 / 삭제 (날짜 섹션)

    fun add(todo: String, dateString: String) {
        val item = TodoData(date = dateString, todo = todo, isImportant = false)

        if (sections.isNotEmpty() && dates.lastOrNull() == dateString) {
            sections.last().add(item)
        } else {
            sections.add(mutableListOf(item))
            dates.add(dateString)
        }
        save()
    }

    fun updateText(position: Position, text: String) {
        todoAt(position) ?: return
        sections[position.section][position.row] =
            sections[position.section][position.row].copy(todo = text)
        save()
    }

    fun toggleImportant(position: Position) {
        val item = todoAt(position) ?: return
        sections[position.section][position.row] = item.copy(isImportant = !item.isImportant)
        save()
    }

    /** 항목을 삭제하고, 섹션이 비면 섹션까지 제거한다. (item, sectionRemoved) 반환 */
    fun remove(position: Position): Pair<TodoData, Boolean>? {
        val item = todoAt(position) ?: return null

        sections[position.section].removeAt(position.row)

        var sectionRemoved = false
        if (sections[position.section].isEmpty()) {
            sections.removeAt(position.section)
            dates.removeAt(position.section)
            sectionRemoved = true
        }
        save()
        return item to sectionRemoved
    }

    // 순서 변경 (드래그)

    /** 드래그 이동. 다른 날짜 섹션으로 이동하면 항목의 날짜가 해당 섹션 날짜로 바뀐다. 실제 삽입 위치 반환 */
    fun move(from: Position, to: Position): Position? {
        if (from == to) return null
        var item = todoAt(from) ?: return null

        var destSection = to.section
        sections[from.section].removeAt(from.row)
        if (sections[from.section].isEmpty()) {
            sections.removeAt(from.section)
            dates.removeAt(from.section)
            if (destSection > from.section) {
                destSection -= 1
            }
        }

        if (destSection !in dates.indices) {
            val fallback = insertIntoDateSections(item)
            save()
            return fallback
        }

        if (from.section != to.section) {
            item = item.copy(date = dates[destSection])
        }

        val row = minOf(to.row, sections[destSection].size)
        sections[destSection].add(row, item)
        save()
        return Position(destSection, row)
    }

    fun removeEmptyDateSections(): List<Int> {
        val removed = mutableListOf<Int>()
        for (index in sections.indices.reversed()) {
            if (sections[index].isEmpty()) {
                sections.removeAt(index)
                dates.removeAt(index)
                removed.add(index)
            }
        }
        return removed
    }

    // 고정 (전역, 스티키 바)

    fun pinnedTodo(index: Int): TodoData? = pinned.getOrNull(index)

    /** 날짜 섹션 항목을 고정 목록 맨 위로 옮긴다 */
    fun pin(position: Position) {
        val item = todoAt(position) ?: return

        sections[position.section].removeAt(position.row)
        if (sections[position.section].isEmpty()) {
            sections.removeAt(position.section)
            dates.removeAt(position.section)
        }
        pinned.add(0, item.copy(isPinned = true))
        save()
    }

    /** 고정 해제 — 원래 날짜 섹션으로 복귀 (섹션이 없으면 날짜순 위치에 새로 만든다). 복귀 위치 반환 */
    fun unpin(index: Int): Position? {
        if (index !in pinned.indices) return null

        val item = pinned.removeAt(index).copy(isPinned = false)
        val destination = insertIntoDateSections(item)
        save()
        return destination
    }

    fun updatePinnedText(index: Int, text: String) {
        if (index !in pinned.indices) return
        pinned[index] = pinned[index].copy(todo = text)
        save()
    }

    fun removePinned(index: Int): TodoData? {
        if (index !in pinned.indices) return null
        val item = pinned.removeAt(index)
        save()
        return item
    }

    /** 날짜 순서를 지키며 날짜 섹션에 삽입하고, 삽입된 위치를 반환한다 */
    private fun insertIntoDateSections(item: TodoData): Position {
        val dateIdx = dates.indexOf(item.date)
        if (dateIdx != -1) {
            sections[dateIdx].add(item)
            return Position(dateIdx, sections[dateIdx].size - 1)
        }

        val insertIdx = dates.indexOfFirst { it > item.date }.let { if (it == -1) dates.size else it }
        dates.add(insertIdx, item.date)
        sections.add(insertIdx, mutableListOf(item))
        return Position(insertIdx, 0)
    }

    // 아카이브 (완료 처리)

    fun loadArchive(): Pair<List<List<TodoData>>, List<String>> {
        val datas = decodeSections(storage.getString(Keys.ARCHIVE_TODOS))
        var dates = decodeDates(storage.getString(Keys.ARCHIVE_DATES))
        if (dates.size != datas.size) {
            dates = datas.map { it.firstOrNull()?.date ?: "" }.toMutableList()
        }
        return datas.map { it.toList() } to dates.toList()
    }

    /** 완료 항목들을 아카이브의 완료 날짜 섹션에 추가. 새 날짜는 맨 앞(최신순). 고정 상태 해제 */
    fun appendToArchive(items: List<TodoData>, dateString: String) {
        if (items.isEmpty()) return

        val unpinnedItems = items.map { it.copy(isPinned = false) }

        val (loadedDatas, loadedDates) = loadArchive()
        val archiveDatas = loadedDatas.map { it.toMutableList() }.toMutableList()
        val archiveDates = loadedDates.toMutableList()

        val index = archiveDates.indexOf(dateString)
        if (index != -1) {
            archiveDatas[index].addAll(unpinnedItems)
        } else {
            archiveDatas.add(0, unpinnedItems.toMutableList())
            archiveDates.add(0, dateString)
        }

        storage.putString(Keys.ARCHIVE_TODOS, json.encodeToString<List<List<TodoData>>>(archiveDatas))
        storage.putString(Keys.ARCHIVE_DATES, json.encodeToString<List<String>>(archiveDates))
    }

    // 일괄 처리 (날짜 섹션)

    /** 선택 항목들을 아카이브로 이동 */
    fun batchArchive(positions: List<Position>, dateString: String) {
        val sorted = positions.sortedWith(compareBy({ it.section }, { it.row }))
        val items = sorted.mapNotNull { todoAt(it) }
        appendToArchive(items, dateString)
        batchRemove(sorted)
    }

    // 아카이브 조작 (안드로이드 확장 — iOS는 ArchiveViewController에 산재)

    /** 아카이브 항목을 원래 날짜 섹션으로 복원. 복원 위치 반환 */
    fun restoreFromArchive(position: Position): Position? {
        val item = archiveRemove(position) ?: return null
        val destination = insertIntoDateSections(item.copy(isPinned = false))
        save()
        return destination
    }

    /** 아카이브 항목 삭제 */
    fun archiveRemove(position: Position): TodoData? =
        mutateArchive(position) { datas, _ -> datas[position.section].removeAt(position.row) }

    /** 아카이브 항목 텍스트 수정 */
    fun archiveUpdateText(position: Position, text: String) {
        mutateArchive(position) { datas, item ->
            datas[position.section][position.row] = item.copy(todo = text)
        }
    }

    /** 아카이브 항목 중요 표시 토글 */
    fun archiveToggleImportant(position: Position) {
        mutateArchive(position) { datas, item ->
            datas[position.section][position.row] = item.copy(isImportant = !item.isImportant)
        }
    }

    /** 아카이브를 읽어 변형하고 빈 섹션 정리 후 저장한다. 대상 항목 반환 */
    private fun mutateArchive(
        position: Position,
        mutation: (MutableList<MutableList<TodoData>>, TodoData) -> Any?,
    ): TodoData? {
        val (loadedDatas, loadedDates) = loadArchive()
        val datas = loadedDatas.map { it.toMutableList() }.toMutableList()
        val dates = loadedDates.toMutableList()
        val item = datas.getOrNull(position.section)?.getOrNull(position.row) ?: return null

        mutation(datas, item)

        for (index in datas.indices.reversed()) {
            if (datas[index].isEmpty()) {
                datas.removeAt(index)
                dates.removeAt(index)
            }
        }
        storage.putString(Keys.ARCHIVE_TODOS, json.encodeToString<List<List<TodoData>>>(datas))
        storage.putString(Keys.ARCHIVE_DATES, json.encodeToString<List<String>>(dates))
        return item
    }

    /** 선택 항목들을 완전히 삭제 (아카이브로 가지 않음) */
    fun batchDelete(positions: List<Position>) {
        batchRemove(positions.sortedWith(compareBy({ it.section }, { it.row })))
    }

    /** 인덱스 밀림을 피하기 위해 정렬된 목록을 역순으로 제거한다 */
    private fun batchRemove(sortedAscending: List<Position>) {
        for (position in sortedAscending.reversed()) {
            if (position.section !in sections.indices) continue
            if (position.row !in sections[position.section].indices) continue
            sections[position.section].removeAt(position.row)
        }
        removeEmptyDateSections()
        save()
    }

    private fun decodeSections(raw: String?): MutableList<MutableList<TodoData>> =
        raw?.let { runCatching { json.decodeFromString<List<List<TodoData>>>(it) }.getOrNull() }
            .orEmpty()
            .filter { it.isNotEmpty() }
            .map { it.toMutableList() }
            .toMutableList()

    private fun decodeDates(raw: String?): MutableList<String> =
        raw?.let { runCatching { json.decodeFromString<List<String>>(it) }.getOrNull() }
            .orEmpty()
            .toMutableList()
}
