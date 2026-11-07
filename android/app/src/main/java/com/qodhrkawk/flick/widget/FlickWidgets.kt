package com.qodhrkawk.flick.widget

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.data.smallWidgetItems
import com.qodhrkawk.flick.data.widgetLine
import com.qodhrkawk.flick.ui.theme.ThemeColors
import com.qodhrkawk.flick.ui.todayString

/** 홈 위젯: 고정 우선 + 최근 항목. 중형 5줄 / 대형 10줄 */
class FlickHomeWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetBody(WidgetKind.HOME) }
    }
}

class FlickHomeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FlickHomeWidget()
}

/** 오늘 위젯: 오늘 날짜 항목만 */
class FlickTodayWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetBody(WidgetKind.TODAY) }
    }
}

class FlickTodayWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FlickTodayWidget()
}

/** 소형(1:1) 위젯: 머리글 없이 최근 3개 (iOS 3.0.1 `.systemSmall`). 안드로이드는 크기별 위젯을 따로 고른다 */
class FlickSmallWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetBody(WidgetKind.SMALL) }
    }
}

class FlickSmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FlickSmallWidget()
}

private enum class WidgetKind { HOME, TODAY, SMALL }

@Composable
private fun WidgetBody(kind: WidgetKind) {
    val context = LocalContext.current
    val (themeIndex, trait) = WidgetUpdater.readThemeTrait(context)
    // 시스템 다크모드가 아니라 앱 설정값 기준으로 색을 정한다 (iOS P0 수정과 동일 원칙)
    val systemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES
    val dark = when (trait) {
        SettingsStore.TRAIT_LIGHT -> false
        SettingsStore.TRAIT_DARK -> true
        else -> systemDark
    }
    val themeColor = ThemeColors.getOrElse(themeIndex) { ThemeColors[3] }
    val bg = if (dark) Color(0xFF202020) else Color(0xFFFFFFFF)
    val textColor = if (dark) Color(0xFFD1D1D1) else Color(0xFF3E3E3E)
    val subColor = if (dark) Color(0xFF585858) else Color(0xFF9C9C9C)

    val items = when (kind) {
        WidgetKind.HOME -> WidgetUpdater.readWidgetItems(context)
        WidgetKind.TODAY -> WidgetUpdater.readTodayItems(context, todayString()).take(10)
        WidgetKind.SMALL -> smallWidgetItems(WidgetUpdater.readWidgetItems(context))
    }
    val maxRows = when {
        kind == WidgetKind.SMALL -> items.size
        LocalSize.current.height >= 220.dp -> 10
        else -> 5
    }

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(bg))
            .cornerRadius(16.dp)
            .padding(14.dp),
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            if (kind != WidgetKind.SMALL) {
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    Text(
                        if (kind == WidgetKind.TODAY) "오늘" else "Flick",
                        style = TextStyle(
                            color = ColorProvider(themeColor),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                }
                Spacer(GlanceModifier.height(6.dp))
            }

            if (items.isEmpty()) {
                Text(
                    "할 일을 모두 완료했어요!",
                    style = TextStyle(color = ColorProvider(subColor), fontSize = 13.sp),
                )
            } else {
                items.take(maxRows).forEach { todo ->
                    WidgetRow(todo, themeColor, textColor)
                }
            }
        }
    }
}

@Composable
private fun WidgetRow(todo: TodoData, themeColor: Color, textColor: Color) {
    Row(modifier = GlanceModifier.fillMaxWidth().padding(vertical = 2.dp)) {
        if (todo.isPinned) {
            Box(
                modifier = GlanceModifier
                    .width(4.dp)
                    .height(14.dp)
                    .background(ColorProvider(themeColor))
                    .cornerRadius(2.dp),
            ) {}
            Spacer(GlanceModifier.width(6.dp))
        }
        Text(
            widgetLine(todo.todo),
            style = TextStyle(
                color = ColorProvider(if (todo.isImportant) themeColor else textColor),
                fontSize = 13.sp,
            ),
            maxLines = 1,
        )
    }
}
