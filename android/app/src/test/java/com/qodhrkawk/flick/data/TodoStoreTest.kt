package com.qodhrkawk.flick.data

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * iOS `TDT/Tests/TodoStoreTests.swift`의 19개 케이스를 그대로 이식.
 * 테스트 이름 뒤 숫자는 iOS 테스트 번호.
 */
class TodoStoreTest {

    private val json = Json

    class InMemoryKeyValueStore : KeyValueStore {
        private val map = mutableMapOf<String, String>()
        override fun getString(key: String): String? = map[key]
        override fun putString(key: String, value: String?) {
            if (value == null) map.remove(key) else map[key] = value
        }
    }

    private fun td(
        text: String,
        date: String,
        pinned: Boolean = false,
        important: Boolean = false,
    ) = TodoData(date = date, todo = text, isImportant = important, isPinned = pinned)

    private fun pos(section: Int, row: Int) = Position(section, row)

    private fun freshStorage(
        sections: List<List<TodoData>>,
        pinned: List<TodoData> = emptyList(),
    ): InMemoryKeyValueStore {
        val storage = InMemoryKeyValueStore()
        storage.putString(TodoStore.Keys.TODOS, json.encodeToString(sections))
        storage.putString(TodoStore.Keys.DATES, json.encodeToString(sections.map { it.firstOrNull()?.date ?: "" }))
        if (pinned.isNotEmpty()) {
            storage.putString(TodoStore.Keys.PINNED, json.encodeToString(pinned))
        }
        return storage
    }

    private fun freshStore(
        sections: List<List<TodoData>>,
        pinned: List<TodoData> = emptyList(),
    ): TodoStore {
        val store = TodoStore(freshStorage(sections, pinned))
        store.load()
        return store
    }

    private fun texts(section: List<TodoData>) = section.map { it.todo }

    // 1. 구버전 데이터(isPinned 없음) 디코딩 호환
    @Serializable
    data class LegacyTodoData(val date: String, val todo: String, val isImportant: Boolean)

    @Test
    fun `1 구버전 데이터 디코딩 - isPinned 기본값 false, 고정 목록 비어 있음`() {
        val storage = InMemoryKeyValueStore()
        val legacy = listOf(listOf(LegacyTodoData("2026.07.11", "old item", true)))
        storage.putString(TodoStore.Keys.TODOS, json.encodeToString(legacy))
        storage.putString(TodoStore.Keys.DATES, json.encodeToString(listOf("2026.07.11")))
        val store = TodoStore(storage)
        store.load()

        assertEquals(1, store.todoDatas.size)
        assertFalse(store.todoDatas[0][0].isPinned)
        assertTrue(store.todoDatas[0][0].isImportant)
        assertTrue(store.pinnedDatas.isEmpty())
    }

    @Test
    fun `2a add - 같은 날짜는 기존 섹션에 추가`() {
        val store = freshStore(listOf(listOf(td("a", "2026.07.11"))))
        store.add(todo = "b", dateString = "2026.07.11")
        assertEquals(1, store.todoDatas.size)
        assertEquals(2, store.todoDatas[0].size)
    }

    @Test
    fun `2b add - 새 날짜는 새 섹션 생성`() {
        val store = freshStore(listOf(listOf(td("a", "2026.07.11"))))
        store.add(todo = "b", dateString = "2026.07.11")
        store.add(todo = "c", dateString = "2026.07.12")
        assertEquals(2, store.todoDatas.size)
        assertEquals(listOf("2026.07.11", "2026.07.12"), store.dateInfo)
    }

    @Test
    fun `3 move - 섹션 내 이동`() {
        val store = freshStore(listOf(listOf(td("a", "d1"), td("b", "d1"), td("c", "d1"))))
        val dest = store.move(from = pos(0, 0), to = pos(0, 2))
        assertEquals(listOf("b", "c", "a"), texts(store.todoDatas[0]))
        assertEquals(pos(0, 2), dest)
    }

    @Test
    fun `4 move - 날짜 섹션 간 이동 시 date 변경`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1"), td("b", "d1")),
                listOf(td("c", "d2")),
            )
        )
        store.move(from = pos(0, 0), to = pos(1, 1))
        assertEquals(listOf("c", "a"), texts(store.todoDatas[1]))
        assertEquals("d2", store.todoDatas[1][1].date)
    }

    @Test
    fun `5 move - 소스 섹션이 비면 섹션과 날짜 제거`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1")),
                listOf(td("b", "d2")),
            )
        )
        store.move(from = pos(0, 0), to = pos(1, 1))
        assertEquals(1, store.todoDatas.size)
        assertEquals(listOf("d2"), store.dateInfo)
        assertEquals(listOf("b", "a"), texts(store.todoDatas[0]))
    }

    @Test
    fun `6 pin - 고정 목록 맨 위로, 원래 날짜 보존`() {
        val store = freshStore(
            listOf(listOf(td("a", "d1"), td("b", "d1"))),
            pinned = listOf(td("p", "d0", pinned = true)),
        )
        store.pin(pos(0, 1))
        assertEquals(listOf("b", "p"), store.pinnedDatas.map { it.todo })
        assertTrue(store.pinnedDatas[0].isPinned)
        assertEquals("d1", store.pinnedDatas[0].date)
        assertEquals(listOf("a"), texts(store.todoDatas[0]))
    }

    @Test
    fun `7 pin - 마지막 항목 고정 시 빈 섹션 제거`() {
        val store = freshStore(
            listOf(
                listOf(td("only", "d1")),
                listOf(td("b", "d2")),
            )
        )
        store.pin(pos(0, 0))
        assertEquals(1, store.todoDatas.size)
        assertEquals(listOf("d2"), store.dateInfo)
        assertEquals(listOf("only"), store.pinnedDatas.map { it.todo })
    }

    @Test
    fun `8 unpin - 기존 날짜 섹션 끝으로 복귀`() {
        val store = freshStore(
            listOf(listOf(td("a", "d1"))),
            pinned = listOf(td("p", "d1", pinned = true)),
        )
        val unpinPos = store.unpin(0)
        assertEquals(pos(0, 1), unpinPos)
        assertTrue(store.pinnedDatas.isEmpty())
        assertEquals(listOf("a", "p"), texts(store.todoDatas[0]))
        assertFalse(store.todoDatas[0][1].isPinned)
    }

    @Test
    fun `9 unpin - 사라진 날짜 섹션을 날짜순으로 재생성`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1")),
                listOf(td("c", "d3")),
            ),
            pinned = listOf(td("p", "d2", pinned = true)),
        )
        val recreatePos = store.unpin(0)
        assertEquals(listOf("d1", "d2", "d3"), store.dateInfo)
        assertEquals(listOf("p"), texts(store.todoDatas[1]))
        assertEquals(pos(1, 0), recreatePos)
    }

    @Test
    fun `10a updatePinnedText - 고정 항목 텍스트 수정`() {
        val store = freshStore(
            listOf(listOf(td("a", "d1"))),
            pinned = listOf(td("p1", "d0", pinned = true), td("p2", "d0", pinned = true)),
        )
        store.updatePinnedText(1, "p2-수정")
        assertEquals("p2-수정", store.pinnedDatas[1].todo)
    }

    @Test
    fun `10b removePinned - 고정 항목 삭제`() {
        val store = freshStore(
            listOf(listOf(td("a", "d1"))),
            pinned = listOf(td("p1", "d0", pinned = true), td("p2", "d0", pinned = true)),
        )
        val removed = store.removePinned(0)
        assertEquals("p1", removed?.todo)
        assertEquals(listOf("p2"), store.pinnedDatas.map { it.todo })
    }

    @Test
    fun `11 load - 섹션 내 고정 항목을 전역 고정으로 마이그레이션`() {
        val storage = InMemoryKeyValueStore()
        storage.putString(
            TodoStore.Keys.TODOS,
            json.encodeToString(listOf(listOf(td("a", "d1"), td("p", "d1", pinned = true)))),
        )
        storage.putString(TodoStore.Keys.DATES, json.encodeToString(listOf("d1")))
        val store = TodoStore(storage)
        store.load()

        assertEquals(listOf("p"), store.pinnedDatas.map { it.todo })
        assertEquals(listOf("a"), texts(store.todoDatas[0]))
    }

    @Test
    fun `12a batchArchive - 원본에서 제거, 빈 섹션 정리`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1"), td("b", "d1")),
                listOf(td("c", "d2")),
            )
        )
        store.batchArchive(listOf(pos(0, 0), pos(1, 0)), dateString = "2026.07.19")
        assertEquals(1, store.todoDatas.size)
        assertEquals(listOf("b"), texts(store.todoDatas[0]))
    }

    @Test
    fun `12b batchArchive - 아카이브 완료 날짜 섹션에 추가`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1"), td("b", "d1")),
                listOf(td("c", "d2")),
            )
        )
        store.batchArchive(listOf(pos(0, 0), pos(1, 0)), dateString = "2026.07.19")
        val (datas, dates) = store.loadArchive()
        assertEquals(listOf("2026.07.19"), dates)
        assertEquals(listOf("a", "c"), texts(datas[0]))
    }

    @Test
    fun `12c appendToArchive - isPinned 해제`() {
        val store = freshStore(listOf(listOf(td("a", "d1"))))
        store.appendToArchive(listOf(td("p", "d0", pinned = true)), dateString = "2026.07.19")
        val (datas, _) = store.loadArchive()
        assertEquals(false, datas[0].last().isPinned)
    }

    @Test
    fun `13 batchDelete - 여러 섹션에 걸친 삭제와 빈 섹션 정리`() {
        val store = freshStore(
            listOf(
                listOf(td("a", "d1"), td("b", "d1")),
                listOf(td("c", "d2")),
                listOf(td("d", "d3")),
            )
        )
        store.batchDelete(listOf(pos(0, 1), pos(1, 0), pos(2, 0)))
        assertEquals(1, store.todoDatas.size)
        assertEquals(listOf("a"), texts(store.todoDatas[0]))
        assertEquals(listOf("d1"), store.dateInfo)
    }

    @Test
    fun `14 load - dateInfo 개수 불일치 시 데이터에서 재구성`() {
        val storage = InMemoryKeyValueStore()
        storage.putString(
            TodoStore.Keys.TODOS,
            json.encodeToString(listOf(listOf(td("a", "d1")), listOf(td("b", "d2")))),
        )
        storage.putString(TodoStore.Keys.DATES, json.encodeToString(listOf("d1")))
        val store = TodoStore(storage)
        store.load()

        assertEquals(listOf("d1", "d2"), store.dateInfo)
    }

    // 이하 안드로이드 확장 — 아카이브 조작 (iOS는 ArchiveViewController에 산재하던 로직)

    @Test
    fun `A1 restoreFromArchive - 원래 날짜 섹션으로 복원, 섹션 없으면 날짜순 재생성`() {
        val store = freshStore(listOf(listOf(td("a", "d1")), listOf(td("c", "d3"))))
        store.appendToArchive(listOf(td("x", "d2")), dateString = "d9")
        val restorePos = store.restoreFromArchive(pos(0, 0))

        assertEquals(pos(1, 0), restorePos)
        assertEquals(listOf("d1", "d2", "d3"), store.dateInfo)
        assertEquals(listOf("x"), texts(store.todoDatas[1]))
        val (datas, dates) = store.loadArchive()
        assertTrue(datas.isEmpty())
        assertTrue(dates.isEmpty())
    }

    @Test
    fun `A2 archiveRemove - 아카이브에서 삭제, 빈 섹션 정리`() {
        val store = freshStore(listOf(listOf(td("a", "d1"))))
        store.appendToArchive(listOf(td("x", "d2"), td("y", "d2")), dateString = "d9")
        val removed = store.archiveRemove(pos(0, 0))

        assertEquals("x", removed?.todo)
        val (datas, dates) = store.loadArchive()
        assertEquals(listOf("y"), texts(datas[0]))
        assertEquals(listOf("d9"), dates)

        store.archiveRemove(pos(0, 0))
        val (datas2, dates2) = store.loadArchive()
        assertTrue(datas2.isEmpty())
        assertTrue(dates2.isEmpty())
    }

    @Test
    fun `A3 archiveUpdateText - 아카이브 항목 텍스트 수정`() {
        val store = freshStore(listOf(listOf(td("a", "d1"))))
        store.appendToArchive(listOf(td("x", "d2")), dateString = "d9")
        store.archiveUpdateText(pos(0, 0), "x-수정")
        val (datas, _) = store.loadArchive()
        assertEquals("x-수정", datas[0][0].todo)
    }

    @Test
    fun `A4 archiveToggleImportant - 아카이브 항목 중요 토글`() {
        val store = freshStore(listOf(listOf(td("a", "d1"))))
        store.appendToArchive(listOf(td("x", "d2")), dateString = "d9")
        store.archiveToggleImportant(pos(0, 0))
        val (datas, _) = store.loadArchive()
        assertTrue(datas[0][0].isImportant)
    }

    @Test
    fun `15 save-load 라운드트립 - 고정 목록 유지`() {
        val storage = freshStorage(
            listOf(listOf(td("a", "d1", important = true))),
            pinned = listOf(td("p", "d0", pinned = true)),
        )
        val store = TodoStore(storage)
        store.load()
        store.save()

        val reloaded = TodoStore(storage)
        reloaded.load()
        assertEquals(listOf("p"), reloaded.pinnedDatas.map { it.todo })
        assertTrue(reloaded.pinnedDatas[0].isPinned)
        assertTrue(reloaded.todoDatas[0][0].isImportant)
    }
}
