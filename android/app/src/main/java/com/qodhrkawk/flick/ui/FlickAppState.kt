package com.qodhrkawk.flick.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.qodhrkawk.flick.data.Position
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.data.TodoStore
import java.time.LocalDate
import java.time.format.DateTimeFormatter

data class DateSection(val date: String, val items: List<TodoData>)

private val dateFormatter = DateTimeFormatter.ofPattern("yyyy.MM.dd")

fun todayString(): String = LocalDate.now().format(dateFormatter)

/**
 * UI 상태 홀더. TodoStore가 진실의 원천이고, 여기서는 조작 후 스냅샷을 Compose 상태로 복사한다.
 * 모든 조작은 id로 그 순간의 실제 위치를 재조회한다 — 연속 스와이프 시 stale index 함정 방지
 * (iOS 3.0 P0 버그, handoff 4장 8번).
 */
class FlickAppState(
    private val store: TodoStore,
    private val settings: SettingsStore,
    private val onDataChanged: () -> Unit,
) {
    var sections by mutableStateOf<List<DateSection>>(emptyList())
        private set
    var pinned by mutableStateOf<List<TodoData>>(emptyList())
        private set
    var archiveSections by mutableStateOf<List<DateSection>>(emptyList())
        private set
    var themeIndex by mutableIntStateOf(settings.theme)
        private set
    var trait by mutableStateOf(settings.trait)
        private set
    var pinnedCollapsed by mutableStateOf(settings.pinnedBarCollapsed)
        private set

    fun start() {
        store.load()
        if (!settings.initiated) {
            val today = todayString()
            store.add("왼쪽으로 밀어서 완료 상태로 만들어 보세요.", today)
            store.add("두 번 탭해서 중요 표시를 해 보세요.", today)
            store.add("길게 눌러서 메모를 삭제하거나 수정할 수 있어요.", today)
            settings.initiated = true
        }
        refresh()
    }

    private fun refresh() {
        sections = store.dateInfo.zip(store.todoDatas) { date, items -> DateSection(date, items.toList()) }
        pinned = store.pinnedDatas.toList()
        val (archiveDatas, archiveDates) = store.loadArchive()
        archiveSections = archiveDates.zip(archiveDatas) { date, items -> DateSection(date, items.toList()) }
        onDataChanged()
    }

    // 조회

    fun positionOf(id: String): Position? {
        sections.forEachIndexed { s, section ->
            section.items.forEachIndexed { r, item ->
                if (item.id == id) return Position(s, r)
            }
        }
        return null
    }

    private fun archivePositionOf(id: String): Position? {
        archiveSections.forEachIndexed { s, section ->
            section.items.forEachIndexed { r, item ->
                if (item.id == id) return Position(s, r)
            }
        }
        return null
    }

    fun find(id: String): TodoData? =
        sections.firstNotNullOfOrNull { sec -> sec.items.find { it.id == id } }
            ?: pinned.find { it.id == id }

    fun findInArchive(id: String): TodoData? =
        archiveSections.firstNotNullOfOrNull { sec -> sec.items.find { it.id == id } }

    fun isPinned(id: String): Boolean = pinned.any { it.id == id }

    // 날짜 섹션 조작

    fun add(text: String) {
        store.add(text, todayString())
        refresh()
    }

    /** 완료: 완료 시점의 오늘 날짜로 아카이브 이동 (원래 적은 날짜가 아님). 고정 항목도 동일 */
    fun complete(id: String) {
        val pinnedIndex = pinned.indexOfFirst { it.id == id }
        val item = if (pinnedIndex != -1) {
            store.removePinned(pinnedIndex)
        } else {
            val position = positionOf(id) ?: return
            store.remove(position)?.first
        } ?: return
        store.appendToArchive(listOf(item), todayString())
        refresh()
    }

    fun delete(id: String) {
        if (isPinned(id)) {
            val index = pinned.indexOfFirst { it.id == id }
            store.removePinned(index)
        } else {
            val position = positionOf(id) ?: return
            store.remove(position)
        }
        refresh()
    }

    fun toggleImportant(id: String) {
        val position = positionOf(id) ?: return
        store.toggleImportant(position)
        refresh()
    }

    fun updateText(id: String, text: String) {
        if (isPinned(id)) {
            val index = pinned.indexOfFirst { it.id == id }
            store.updatePinnedText(index, text)
        } else {
            val position = positionOf(id) ?: return
            store.updateText(position, text)
        }
        refresh()
    }

    // 고정

    fun pin(id: String) {
        val position = positionOf(id) ?: return
        store.pin(position)
        refresh()
    }

    fun unpin(id: String) {
        val index = pinned.indexOfFirst { it.id == id }
        if (index == -1) return
        store.unpin(index)
        refresh()
    }

    fun togglePinnedCollapsed() {
        pinnedCollapsed = !pinnedCollapsed
        settings.pinnedBarCollapsed = pinnedCollapsed
    }

    // 드래그 (셀 레벨 제스처에서 호출)

    /** 다른 항목 위를 지날 때. 같은 섹션이면 iOS move 의미론, 섹션이 다르면 방향에 따라 앞/뒤 삽입 */
    fun moveOverItem(dragId: String, targetId: String) {
        val from = positionOf(dragId) ?: return
        val target = positionOf(targetId) ?: return
        val to = if (from.section == target.section) {
            target
        } else {
            val movingDown = target.section > from.section
            Position(target.section, target.row + if (movingDown) 1 else 0)
        }
        store.move(from, to)
        refresh()
    }

    /** 헤더를 넘어갈 때. 아래로면 그 섹션 첫 번째, 위로면 이전 섹션 마지막 */
    fun moveOverHeader(dragId: String, headerDate: String, movingDown: Boolean): Boolean {
        val from = positionOf(dragId) ?: return false
        val headerSection = sections.indexOfFirst { it.date == headerDate }
        if (headerSection == -1) return false

        val to = if (movingDown) {
            Position(headerSection, 0)
        } else {
            val above = headerSection - 1
            if (above < 0) return false
            if (above == from.section) return false
            Position(above, sections[above].items.size)
        }
        store.move(from, to) ?: return false
        refresh()
        return true
    }

    // 일괄 처리

    fun batchComplete(ids: List<String>) {
        val positions = ids.mapNotNull { positionOf(it) }
        if (positions.isEmpty()) return
        store.batchArchive(positions, todayString())
        refresh()
    }

    fun batchDelete(ids: List<String>) {
        val positions = ids.mapNotNull { positionOf(it) }
        if (positions.isEmpty()) return
        store.batchDelete(positions)
        refresh()
    }

    // 아카이브

    /** 복원: 항목의 원래 date로 메인에 복귀 */
    fun restore(id: String) {
        val position = archivePositionOf(id) ?: return
        store.restoreFromArchive(position)
        refresh()
    }

    fun archiveDelete(id: String) {
        val position = archivePositionOf(id) ?: return
        store.archiveRemove(position)
        refresh()
    }

    fun archiveUpdateText(id: String, text: String) {
        val position = archivePositionOf(id) ?: return
        store.archiveUpdateText(position, text)
        refresh()
    }

    fun archiveToggleImportant(id: String) {
        val position = archivePositionOf(id) ?: return
        store.archiveToggleImportant(position)
        refresh()
    }

    // 설정

    fun setTheme(index: Int) {
        themeIndex = index
        settings.theme = index
        onDataChanged()
    }

    fun changeTrait(value: String) {
        trait = value
        settings.trait = value
        onDataChanged()
    }
}
