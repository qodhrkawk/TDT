package com.qodhrkawk.flick.data

import org.junit.Assert.assertEquals
import org.junit.Test

/** iOS WidgetDataManager.updateData()의 목록 계산 규칙 검증 */
class WidgetDataTest {

    private fun td(text: String, date: String = "d1", pinned: Boolean = false) =
        TodoData(date = date, todo = text, isPinned = pinned)

    @Test
    fun `고정이 앞, 이후 최근 항목이 원래 순서로 이어진다`() {
        val pinned = listOf(td("p1", pinned = true), td("p2", pinned = true))
        val sections = listOf(
            listOf(td("a"), td("b")),
            listOf(td("c"), td("d")),
        )
        val result = computeWidgetItems(pinned, sections)
        assertEquals(listOf("p1", "p2", "a", "b", "c", "d"), result.map { it.todo })
    }

    @Test
    fun `capacity는 10에서 고정 개수를 뺀 값 - 최근 것부터 취하고 원래 순서 유지`() {
        val pinned = List(3) { td("p$it", pinned = true) }
        val sections = listOf(List(12) { td("t$it") })
        val result = computeWidgetItems(pinned, sections)
        // capacity 7 → 최근 7개(t5..t11)를 원래 순서로
        assertEquals(
            listOf("p0", "p1", "p2", "t5", "t6", "t7", "t8", "t9", "t10", "t11"),
            result.map { it.todo },
        )
    }

    @Test
    fun `고정이 10개 이상이면 고정만 10개`() {
        val pinned = List(12) { td("p$it", pinned = true) }
        val sections = listOf(listOf(td("a")))
        val result = computeWidgetItems(pinned, sections)
        assertEquals(10, result.size)
        assertEquals("p9", result.last().todo)
    }
}
