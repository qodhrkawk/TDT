package com.qodhrkawk.flick.data

import kotlinx.serialization.Serializable

/**
 * iOS `TDT/TDT/Data/TodoData.swift` 포팅.
 * date는 "yyyy.MM.dd" (zero-pad라 문자열 사전순 = 시간순).
 */
@Serializable
data class TodoData(
    val date: String,
    val todo: String,
    val isImportant: Boolean = false,
    val isPinned: Boolean = false,
)

/** iOS IndexPath(section, row) 대응. 날짜 섹션 좌표계 */
data class Position(val section: Int, val row: Int)

/** 저장소 추상화 — 앱에서는 SharedPreferences/DataStore, 테스트에서는 인메모리 */
interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String?)
}
