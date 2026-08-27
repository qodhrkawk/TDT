package com.qodhrkawk.flick.data

import kotlinx.serialization.Serializable

/**
 * iOS `TDT/TDT/Data/TodoData.swift` 포팅.
 * date는 "yyyy.MM.dd" (zero-pad라 문자열 사전순 = 시간순).
 * id는 안드로이드 확장 — UI가 위치 대신 항목을 식별하기 위한 값.
 * 이동/고정/아카이브를 거쳐도 유지된다 (copy가 id를 보존).
 */
@Serializable
data class TodoData(
    val date: String,
    val todo: String,
    val isImportant: Boolean = false,
    val isPinned: Boolean = false,
    val id: String = newTodoId(),
)

private var idCounter = 0L

/** 세션 내 유일 id. 저장을 거치면 JSON에 실려 영속된다 */
fun newTodoId(): String = "t${System.currentTimeMillis()}-${idCounter++}"

/** iOS IndexPath(section, row) 대응. 날짜 섹션 좌표계 */
data class Position(val section: Int, val row: Int)

/** 저장소 추상화 — 앱에서는 SharedPreferences/DataStore, 테스트에서는 인메모리 */
interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String?)
}
