package com.qodhrkawk.flick.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import com.qodhrkawk.flick.data.KeyValueStore
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.data.SharedPrefsKeyValueStore
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.data.TodoStore
import com.qodhrkawk.flick.data.WidgetSync
import com.qodhrkawk.flick.data.computeWidgetItems
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * 데이터가 바뀔 때마다 위젯용 데이터를 기록하고 위젯을 갱신한다.
 * iOS P0 규칙: 저장소 읽기 실패 시 빈 상태로 덮어쓰지 않고 이전 캐시를 유지한다.
 */
object WidgetUpdater {
    private val json = Json { ignoreUnknownKeys = true }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    fun sync(context: Context) {
        val kv: KeyValueStore = SharedPrefsKeyValueStore(context)
        val settings = SettingsStore(context)

        val rawSections = kv.getString(TodoStore.Keys.TODOS)
        val cached = kv.getString(WidgetSync.KEY_WIDGET_DATA)

        if (rawSections == null && !cached.isNullOrEmpty()) {
            // 읽기 실패로 판단 — 캐시 유지
        } else {
            val sections = decodeSections(rawSections)
            val pinned = kv.getString(TodoStore.Keys.PINNED)
                ?.let { runCatching { json.decodeFromString<List<TodoData>>(it) }.getOrNull() }
                .orEmpty()
            kv.putString(
                WidgetSync.KEY_WIDGET_DATA,
                json.encodeToString(computeWidgetItems(pinned, sections)),
            )
        }
        kv.putString(WidgetSync.KEY_WIDGET_THEME, settings.theme.toString())
        kv.putString(WidgetSync.KEY_WIDGET_TRAIT, settings.trait)

        scope.launch {
            runCatching {
                FlickHomeWidget().updateAll(context)
                FlickTodayWidget().updateAll(context)
            }
        }
    }

    fun decodeSections(raw: String?): List<List<TodoData>> =
        raw?.let { runCatching { json.decodeFromString<List<List<TodoData>>>(it) }.getOrNull() }
            .orEmpty()

    fun readWidgetItems(context: Context): List<TodoData> {
        val kv = SharedPrefsKeyValueStore(context)
        return kv.getString(WidgetSync.KEY_WIDGET_DATA)
            ?.let { runCatching { json.decodeFromString<List<TodoData>>(it) }.getOrNull() }
            .orEmpty()
    }

    fun readTodayItems(context: Context, today: String): List<TodoData> {
        val kv = SharedPrefsKeyValueStore(context)
        return decodeSections(kv.getString(TodoStore.Keys.TODOS))
            .flatten()
            .filter { it.date == today }
    }

    fun readThemeTrait(context: Context): Pair<Int, String> {
        val kv = SharedPrefsKeyValueStore(context)
        val theme = kv.getString(WidgetSync.KEY_WIDGET_THEME)?.toIntOrNull()
            ?: SettingsStore.DEFAULT_THEME
        val trait = kv.getString(WidgetSync.KEY_WIDGET_TRAIT) ?: SettingsStore.TRAIT_SYSTEM
        return theme to trait
    }
}
