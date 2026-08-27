package com.qodhrkawk.flick.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.data.SettingsStore

/** 테마 색 7종 — iOS Theme.swift와 동일 */
val ThemeColors = listOf(
    Color(0xFFD94A2A), // 0 토마토
    Color(0xFFEF9E00), // 1 머스타드
    Color(0xFF03A239), // 2 포레스트
    Color(0xFF0069CA), // 3 플릭 블루 (기본값)
    Color(0xFF8458CC), // 4 파스텔 바이올렛
    Color(0xFFF092B4), // 5 인디 핑크
    Color(0xFF64B3CC), // 6 베이비 블루
)

val ThemeNames = listOf("토마토", "머스타드", "포레스트", "플릭 블루", "파스텔 바이올렛", "인디 핑크", "베이비 블루")

val GmarketSans = FontFamily(
    Font(R.font.gmarket_sans_medium, FontWeight.Normal),
    Font(R.font.gmarket_sans_medium, FontWeight.Medium),
)

/** 날짜 헤더·고정 바 라벨용 (iOS GmarketSansTTFLight 12) */
val GmarketSansLight = FontFamily(
    Font(R.font.gmarket_sans_light, FontWeight.Normal),
)

/** iOS Assets.xcassets 색상셋과 동일한 팔레트 */
data class FlickColors(
    val theme: Color,
    val bg: Color,
    val box: Color,
    val mainText: Color,
    val subText: Color,
    val inactive: Color,
    val inactiveSecondary: Color,
    val textBox: Color,
    val typingText: Color,
    val archiveBox: Color,
    val archiveText: Color,
    val doneText: Color,
    val alert: Color,
    val isDark: Boolean,
)

private fun lightColors(theme: Color) = FlickColors(
    theme = theme,
    bg = Color(0xFFEDEDED),
    box = Color(0xFFFFFFFF),
    mainText = Color(0xFF3E3E3E),
    subText = Color(0xFF9C9C9C),
    inactive = Color(0xFFC2C2C2),
    inactiveSecondary = Color(0xFFD1D1D1),
    textBox = Color(0xFFFBFBFB),
    typingText = Color(0xFF191919),
    archiveBox = Color(0xFFE0E0E0),
    archiveText = Color(0xFFAAAAAA),
    doneText = Color(0xFF7E7E7E),
    alert = Color(0xFFFB629D),
    isDark = false,
)

private fun darkColors(theme: Color) = FlickColors(
    theme = theme,
    bg = Color(0xFF101010),
    box = Color(0xFF202020),
    mainText = Color(0xFFD1D1D1),
    subText = Color(0xFF585858),
    inactive = Color(0xFF484848),
    inactiveSecondary = Color(0xFF4A4A4A),
    textBox = Color(0xFF151515),
    typingText = Color(0xFFE9E9E9),
    archiveBox = Color(0xFF000000),
    archiveText = Color(0xFF8E8E8E),
    doneText = Color(0xFF656565),
    alert = Color(0xFFB23E6A),
    isDark = true,
)

val LocalFlickColors = staticCompositionLocalOf { lightColors(ThemeColors[3]) }

object Flick {
    val colors: FlickColors
        @Composable get() = LocalFlickColors.current
}

fun resolveColors(themeIndex: Int, trait: String, systemDark: Boolean): FlickColors {
    val themeColor = ThemeColors.getOrElse(themeIndex) { ThemeColors[3] }
    val dark = when (trait) {
        SettingsStore.TRAIT_LIGHT -> false
        SettingsStore.TRAIT_DARK -> true
        else -> systemDark
    }
    return if (dark) darkColors(themeColor) else lightColors(themeColor)
}

@Composable
fun FlickTheme(themeIndex: Int, trait: String, content: @Composable () -> Unit) {
    val colors = resolveColors(themeIndex, trait, isSystemInDarkTheme())
    CompositionLocalProvider(LocalFlickColors provides colors, content = content)
}
