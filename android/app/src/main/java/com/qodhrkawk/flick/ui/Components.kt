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
    var lastVelocity = remember(itemId) { floatArrayOf(0f, 0f) } // (velocity px/s, lastTime ms)
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
                        val now = change.uptimeMillis
                        val dt = (now - lastVelocity[1].toLong()).coerceAtLeast(1)
                        lastVelocity[0] = amount / dt * 1000f
                        lastVelocity[1] = now.toFloat()
                        scope.launch {
                            swipeX.snapTo((swipeX.value + amount).coerceIn(-screenWidthPx, 0f))
                        }
                    },
                    onDragEnd = {
                        if (!currentEnabled) return@detectHorizontalDragGestures
                        scope.launch {
                            // 임계값 통과 또는 빠른 왼쪽 플릭(iOS UISwipeGestureRecognizer 감각)
                            if (swipeX.value < -thresholdPx || (swipeX.value < 0 && lastVelocity[0] < -1500f)) {
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

/**
 * 진입 슬라이드인 (iOS willDisplay 애니메이션):
 * 0.1 + 0.05*섹션 + 0.02*행 지연, 0.4초 easeOut, 250px 이동 + 알파 0.2→1
 */
@Composable
fun EnterSlide(
    active: Boolean,
    sectionIndex: Int,
    rowIndex: Int,
    fromRight: Boolean,
    content: @Composable () -> Unit,
) {
    val progress = remember { Animatable(if (active) 1f else 0f) }
    androidx.compose.runtime.LaunchedEffect(active) {
        if (active) {
            progress.snapTo(1f)
            kotlinx.coroutines.delay(100L + sectionIndex * 50L + rowIndex * 20L)
            progress.animateTo(0f, tween(400, easing = androidx.compose.animation.core.EaseOut))
        }
    }
    Box(
        modifier = Modifier.graphicsLayer {
            translationX = (if (fromRight) 250.dp.toPx() else -250.dp.toPx()) * progress.value
            alpha = 1f - progress.value * 0.8f
        },
    ) {
        content()
    }
}
