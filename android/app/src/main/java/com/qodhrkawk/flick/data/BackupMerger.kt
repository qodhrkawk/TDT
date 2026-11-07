package com.qodhrkawk.flick.data

/**
 * iOS `BackupMerger.swift` 포팅 — 가져온 백업 내용을 기기 데이터에 합친다.
 * 기기 데이터는 지우거나 바꾸지 않고 새 항목만 더한다.
 * (안내 세트 정리만 예외: 새 항목이 실제로 추가될 때 기기의 안내 할 일 세트를 지운다.)
 */
data class BackupMergeResult(val merged: BackupContent, val added: Int, val skipped: Int)

object BackupMerger {
    /** 새로 설치한 앱에 들어 있는 안내 할 일 3개 (iOS와 같은 문구) */
    val guideTexts: List<String> = listOf(
        "왼쪽으로 밀어서 완료 상태로 만들어 보세요.",
        "두 번 탭해서 중요 표시를 해 보세요.",
        "한 번 클릭해서 메모를 삭제하거나 수정할 수 있어요.",
    )

    /** completed는 아카이브만 사용, 그 외에는 빈 문자열 */
    private data class Key(val completed: String, val date: String, val todo: String)

    /** today는 기기 데이터를 내보낼 때와 같은 규칙으로 정리해 비교하는 데 쓴다. 저장된 기기 데이터는 고치지 않는다 */
    fun merge(current: BackupContent, incoming: BackupContent, today: String): BackupMergeResult {
        val fileTodos = removingGuideSets(incoming.todos)

        // 기기 안내 세트를 뺀 사본에서 비교하고 삽입한다
        val base = current.copy(todos = removingGuideSets(current.todos))
        val comparable = FlickBackup.sanitized(base, today)

        val todoCounts = HashMap<Key, Int>()
        for (section in comparable.todos) for (item in section.items) todoCounts.increment(todoKey(item))
        for (item in comparable.pinned) todoCounts.increment(todoKey(item))
        val archiveCounts = HashMap<Key, Int>()
        for (section in comparable.archive) for (item in section.items) archiveCounts.increment(archiveKey(section, item))

        var added = 0
        var skipped = 0
        val todoInserter = SectionInserter(base.todos, ascending = true)
        val archiveInserter = SectionInserter(base.archive, ascending = false)
        val newPinned = mutableListOf<BackupItem>()

        for (section in fileTodos) {
            for (item in section.items) {
                if (todoCounts.consume(todoKey(item))) {
                    skipped += 1
                } else {
                    todoInserter.add(item, section.date)
                    added += 1
                }
            }
        }
        for (item in incoming.pinned) {
            if (todoCounts.consume(todoKey(item))) {
                skipped += 1
            } else {
                newPinned.add(item)
                added += 1
            }
        }
        for (section in incoming.archive) {
            for (item in section.items) {
                if (archiveCounts.consume(archiveKey(section, item))) {
                    skipped += 1
                } else {
                    archiveInserter.add(item, section.date)
                    added += 1
                }
            }
        }

        if (added == 0) return BackupMergeResult(current, added = 0, skipped = skipped)
        val merged = BackupContent(
            todos = todoInserter.result(),
            pinned = base.pinned + newPinned,
            archive = archiveInserter.result(),
        )
        return BackupMergeResult(merged, added, skipped)
    }

    // 안내 세트

    private fun isGuide(item: BackupItem, text: String, date: String) =
        item.todo == text && item.date == date && !item.isImportant

    /**
     * 안내 세트: 한 섹션 안에서 세 문구가 같은 date로, 중요 표시 없이 모두 있는 경우.
     * 중요 표시를 한 항목은 사용자가 손댄 것으로 본다.
     */
    private fun guideSetDate(items: List<BackupItem>): String? {
        for (item in items) {
            if (item.todo != guideTexts[0] || item.isImportant) continue
            val date = item.date
            if (guideTexts.all { text -> items.any { isGuide(it, text, date) } }) return date
        }
        return null
    }

    /** 모든 섹션에서 안내 세트를 (여러 개여도 모두) 하나씩 빼고, 그래서 빈 섹션은 버린다 */
    private fun removingGuideSets(sections: List<BackupSection>): List<BackupSection> =
        sections.mapNotNull { section ->
            val items = section.items.toMutableList()
            while (true) {
                val date = guideSetDate(items) ?: break
                for (text in guideTexts) {
                    val index = items.indexOfFirst { isGuide(it, text, date) }
                    if (index != -1) items.removeAt(index)
                }
            }
            if (items.isEmpty() && section.items.isNotEmpty()) null else section.copy(items = items)
        }

    // 비교

    private fun todoKey(item: BackupItem) = Key(completed = "", date = item.date, todo = item.todo)

    private fun archiveKey(section: BackupSection, item: BackupItem) =
        Key(completed = section.date, date = item.date, todo = item.todo)

    private fun HashMap<Key, Int>.increment(key: Key) {
        this[key] = (this[key] ?: 0) + 1
    }

    /** 남은 개수가 있으면 하나 줄이고 true (같은 항목이 이미 있다) */
    private fun HashMap<Key, Int>.consume(key: Key): Boolean {
        val count = this[key] ?: return false
        if (count <= 0) return false
        this[key] = count - 1
        return true
    }

    // 삽입

    /**
     * 같은 날짜 섹션 끝에 붙이고, 없는 날짜는 모아 두었다가 정렬 순서를 지키는 위치에 한 번에 끼운다.
     * (할 일: 첫 더 큰 날짜 앞, 아카이브: 첫 더 작은 날짜 앞)
     */
    private class SectionInserter(sections: List<BackupSection>, private val ascending: Boolean) {
        private val sections: List<MutableList<BackupItem>> = sections.map { it.items.toMutableList() }
        private val dates: List<String> = sections.map { it.date }
        private val existing = HashMap<String, Int>()
        private val pending = HashMap<String, MutableList<BackupItem>>()
        private val pendingOrder = mutableListOf<String>()

        init {
            dates.forEachIndexed { index, date ->
                val day = date.take(10)
                if (FlickBackup.isValidDate(day) && day !in existing) existing[day] = index
            }
        }

        fun add(item: BackupItem, sectionDate: String) {
            val index = existing[sectionDate]
            if (index != null) {
                sections[index].add(item)
            } else {
                pending.getOrPut(sectionDate) {
                    pendingOrder.add(sectionDate)
                    mutableListOf()
                }.add(item)
            }
        }

        fun result(): List<BackupSection> {
            val current = dates.indices.map { BackupSection(dates[it], sections[it].toList()) }
            if (pending.isEmpty()) return current
            val days = dates.map { it.take(10) }

            // 새 날짜가 들어갈 위치: 첫 더 큰(작은) 날짜 앞. 기존 섹션은 정렬되어 있다고 보고 이분 탐색한다
            fun position(date: String): Int {
                var low = 0
                var high = days.size
                while (low < high) {
                    val mid = (low + high) / 2
                    val after = if (ascending) days[mid] > date else days[mid] < date
                    if (after) high = mid else low = mid + 1
                }
                return low
            }

            val byPosition = HashMap<Int, MutableList<String>>()
            for (date in pendingOrder) byPosition.getOrPut(position(date)) { mutableListOf() }.add(date)

            val out = ArrayList<BackupSection>(current.size + pendingOrder.size)
            for (i in 0..current.size) {
                byPosition[i]?.let { newDates ->
                    val ordered = if (ascending) newDates.sorted() else newDates.sortedDescending()
                    for (date in ordered) out.add(BackupSection(date, pending.getValue(date).toList()))
                }
                if (i < current.size) out.add(current[i])
            }
            return out
        }
    }
}
