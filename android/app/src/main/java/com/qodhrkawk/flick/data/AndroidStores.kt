package com.qodhrkawk.flick.data

import android.content.Context
import android.content.SharedPreferences

/**
 * 할 일/아카이브/고정 데이터 저장소. 위젯 프로세스에서도 같은 파일을 읽는다.
 * commit()을 쓰는 이유: 위젯 갱신 브로드캐스트 직전에 디스크 반영을 보장하기 위함.
 */
class SharedPrefsKeyValueStore(context: Context) : KeyValueStore {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    override fun getString(key: String): String? = prefs.getString(key, null)

    override fun putString(key: String, value: String?) {
        prefs.edit().apply {
            if (value == null) remove(key) else putString(key, value)
        }.commit()
    }

    companion object {
        const val PREFS_NAME = "flick_data"
    }
}

/** 설정: 테마(0-6), 화면 스타일(system/light/dark), 첫 실행 플래그, 고정 바 접힘 상태 */
class SettingsStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("flick_settings", Context.MODE_PRIVATE)

    var theme: Int
        get() = prefs.getInt("theme", DEFAULT_THEME)
        set(value) = prefs.edit().putInt("theme", value).apply()

    var trait: String
        get() = prefs.getString("trait", TRAIT_SYSTEM) ?: TRAIT_SYSTEM
        set(value) = prefs.edit().putString("trait", value).apply()

    var initiated: Boolean
        get() = prefs.getBoolean("initiated", false)
        set(value) = prefs.edit().putBoolean("initiated", value).apply()

    var pinnedBarCollapsed: Boolean
        get() = prefs.getBoolean("pinnedBarCollapsed", false)
        set(value) = prefs.edit().putBoolean("pinnedBarCollapsed", value).apply()

    companion object {
        const val DEFAULT_THEME = 3 // 플릭 블루
        const val TRAIT_SYSTEM = "system"
        const val TRAIT_LIGHT = "light"
        const val TRAIT_DARK = "dark"
    }
}

/** 위젯용 데이터 기록 + 위젯 갱신 트리거. 테마/트레잇도 위젯이 읽도록 같은 파일에 복사한다 */
object WidgetSync {
    const val KEY_WIDGET_DATA = "widgetData"
    const val KEY_WIDGET_THEME = "widgetTheme"
    const val KEY_WIDGET_TRAIT = "widgetTrait"
}
