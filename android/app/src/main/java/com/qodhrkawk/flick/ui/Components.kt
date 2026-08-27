package com.qodhrkawk.flick.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

// 시스템 이모지 금지 — 아이콘은 전부 Canvas로 그린다

@Composable
fun ArchiveIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        val stroke = Stroke(width = w * 0.09f, cap = StrokeCap.Round)
        // 뚜껑
        drawRoundRect(
            color = color,
            topLeft = Offset(0f, h * 0.08f),
            size = Size(w, h * 0.22f),
            cornerRadius = CornerRadius(w * 0.06f),
            style = stroke,
        )
        // 본체
        drawRoundRect(
            color = color,
            topLeft = Offset(w * 0.08f, h * 0.34f),
            size = Size(w * 0.84f, h * 0.58f),
            cornerRadius = CornerRadius(w * 0.06f),
            style = stroke,
        )
        // 손잡이
        drawLine(
            color = color,
            start = Offset(w * 0.36f, h * 0.52f),
            end = Offset(w * 0.64f, h * 0.52f),
            strokeWidth = w * 0.09f,
            cap = StrokeCap.Round,
        )
    }
}

@Composable
fun SendIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        val stroke = w * 0.11f
        // 위쪽 화살표
        drawLine(color, Offset(w * 0.5f, h * 0.78f), Offset(w * 0.5f, h * 0.24f), stroke, StrokeCap.Round)
        drawLine(color, Offset(w * 0.26f, h * 0.46f), Offset(w * 0.5f, h * 0.22f), stroke, StrokeCap.Round)
        drawLine(color, Offset(w * 0.74f, h * 0.46f), Offset(w * 0.5f, h * 0.22f), stroke, StrokeCap.Round)
    }
}

@Composable
fun ChevronIcon(color: Color, expanded: Boolean, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        val stroke = w * 0.12f
        val path = Path()
        if (expanded) {
            path.moveTo(w * 0.2f, h * 0.6f)
            path.lineTo(w * 0.5f, h * 0.35f)
            path.lineTo(w * 0.8f, h * 0.6f)
        } else {
            path.moveTo(w * 0.2f, h * 0.4f)
            path.lineTo(w * 0.5f, h * 0.65f)
            path.lineTo(w * 0.8f, h * 0.4f)
        }
        drawPath(path, color, style = Stroke(stroke, cap = StrokeCap.Round))
    }
}

@Composable
fun PinIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        // 압정: 머리 원 + 침
        drawCircle(color, radius = w * 0.28f, center = Offset(w * 0.58f, h * 0.36f))
        drawLine(
            color,
            Offset(w * 0.46f, h * 0.52f),
            Offset(w * 0.2f, h * 0.84f),
            strokeWidth = w * 0.12f,
            cap = StrokeCap.Round,
        )
    }
}

@Composable
fun GearIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val c = Offset(w / 2f, size.height / 2f)
        drawCircle(color, radius = w * 0.18f, center = c, style = Stroke(w * 0.1f))
        for (i in 0 until 8) {
            val angle = Math.toRadians(i * 45.0)
            val from = c + Offset(
                (Math.cos(angle) * w * 0.3f).toFloat(),
                (Math.sin(angle) * w * 0.3f).toFloat(),
            )
            val to = c + Offset(
                (Math.cos(angle) * w * 0.42f).toFloat(),
                (Math.sin(angle) * w * 0.42f).toFloat(),
            )
            drawLine(color, from, to, strokeWidth = w * 0.1f, cap = StrokeCap.Round)
        }
    }
}

@Composable
fun BackIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        val stroke = w * 0.11f
        drawLine(color, Offset(w * 0.7f, h * 0.2f), Offset(w * 0.32f, h * 0.5f), stroke, StrokeCap.Round)
        drawLine(color, Offset(w * 0.32f, h * 0.5f), Offset(w * 0.7f, h * 0.8f), stroke, StrokeCap.Round)
    }
}

@Composable
fun CheckCircle(checked: Boolean, color: Color, inactive: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val w = size.width
        val c = Offset(w / 2f, size.height / 2f)
        if (checked) {
            drawCircle(color, radius = w * 0.46f, center = c)
            val path = Path().apply {
                moveTo(w * 0.3f, w * 0.52f)
                lineTo(w * 0.45f, w * 0.66f)
                lineTo(w * 0.72f, w * 0.36f)
            }
            drawPath(path, Color.White, style = Stroke(w * 0.1f, cap = StrokeCap.Round))
        } else {
            drawCircle(inactive, radius = w * 0.42f, center = c, style = Stroke(w * 0.08f))
        }
    }
}

/**
 * 왼쪽 스와이프 액션 셀 래퍼. 임계값을 넘기면 0.3초 슬라이드아웃 + 그라데이션 후 onAction.
 * 스파이크 검증 패턴: 감지기는 셀(안쪽)에 있어야 리스트 스크롤/페이저보다 먼저 소비한다.
 */
@Composable
fun SwipeToActionCell(
    itemId: String,
    enabled: Boolean,
    gradientColor: Color,
    onAction: (String) -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable (Modifier) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val swipeX = remember(itemId) { Animatable(0f) }
    val density = LocalDensity.current
    val screenWidthPx = with(density) { LocalConfiguration.current.screenWidthDp.dp.toPx() }
    val thresholdPx = with(density) { 90.dp.toPx() }
    val currentId by rememberUpdatedState(itemId)
    val currentEnabled by rememberUpdatedState(enabled)
    val currentAction by rememberUpdatedState(onAction)

    Box(modifier = modifier.fillMaxWidth()) {
        val gestureModifier = Modifier
            .graphicsLayer { translationX = swipeX.value }
            .pointerInput(itemId) {
                detectHorizontalDragGestures(
                    onHorizontalDrag = { change, amount ->
                        if (!currentEnabled) return@detectHorizontalDragGestures
                        change.consume()
                        scope.launch {
                            swipeX.snapTo((swipeX.value + amount).coerceIn(-screenWidthPx, 0f))
                        }
                    },
                    onDragEnd = {
                        if (!currentEnabled) return@detectHorizontalDragGestures
                        scope.launch {
                            if (swipeX.value < -thresholdPx) {
                                swipeX.animateTo(-screenWidthPx, tween(300))
                                currentAction(currentId)
                            } else {
                                swipeX.animateTo(0f, tween(200))
                            }
                        }
                    },
                    onDragCancel = {
                        scope.launch { swipeX.animateTo(0f, tween(200)) }
                    },
                )
            }
        content(gestureModifier)

        // 스와이프 진행에 따라 우측에서 테마색 그라데이션 페이드인
        Box(
            modifier = Modifier
                .matchParentSize()
                .graphicsLayer { alpha = (-swipeX.value / thresholdPx).coerceIn(0f, 1f) }
                .background(
                    Brush.horizontalGradient(
                        listOf(Color.Transparent, gradientColor.copy(alpha = 0.35f))
                    )
                )
        )
    }
}

/** 말풍선 공통 모양 */
val BubbleShape = RoundedCornerShape(8.dp)
val BubblePaddingH: Dp = 18.dp
val BubblePaddingV: Dp = 15.dp
