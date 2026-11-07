package com.qodhrkawk.flick.data

/**
 * iOS `WidgetDataManager.swift`의 위젯 노출 목록 계산 규칙 포팅.
 * capacity = 10 - 고정 개수. 비고정 항목을 최근 것부터 capacity만큼 취해
 * 원래 순서로 되돌린 뒤 고정 + 최근 순으로 이어붙이고 10개로 자른다.
 */
fun computeWidgetItems(
    pinned: List<TodoData>,
    sections: List<List<TodoData>>,
): List<TodoData> {
    val capacity = maxOf(0, 10 - pinned.size)
    val recent = sections.flatten().takeLast(capacity)
    return (pinned + recent).take(10)
}

/** 소형(1:1) 위젯: iOS `.systemSmall`과 동일하게 위젯 목록의 마지막 3개 */
fun smallWidgetItems(items: List<TodoData>): List<TodoData> = items.takeLast(3)

/** 위젯 행은 한 줄이다. 줄바꿈을 그대로 두면 첫 줄이 말줄임되므로 공백으로 잇는다 */
fun widgetLine(text: String): String = text.trim().replace(Regex("\\s*\\R\\s*"), " ")
