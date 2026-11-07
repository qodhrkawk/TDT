package com.qodhrkawk.flick.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseIn
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
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
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChangeIgnoreConsumed
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.data.containedLinks
import com.qodhrkawk.flick.ui.theme.Flick
import kotlin.math.abs
import kotlinx.coroutines.delay
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

private const val SwipeMaxDurationMs = 500L
private const val SwipeAnimationMs = 300
private const val SwipeResetDelayMs = 250L
private val SwipeTriggerDistance = 40.dp
private val SwipeGradientWidth = 75.dp
private val SwipeGradientOverlap = 18.dp

/**
 * iOS UISwipeGestureRecognizer 대응: 왼쪽으로 빠르게 밀면 손을 떼기 전에 바로 발동한다.
 * 오른쪽·세로 이동과 느린 드래그는 소비하지 않아 페이저와 리스트가 그대로 받는다.
 */
private suspend fun PointerInputScope.detectLeftSwipe(isEnabled: () -> Boolean, onSwipe: () -> Unit) {
    val triggerPx = SwipeTriggerDistance.toPx()
    val slop = viewConfiguration.touchSlop
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = false)
        if (!isEnabled()) return@awaitEachGesture

        var total = Offset.Zero
        var tracking = false
        while (true) {
            val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id } ?: break
            if (!change.pressed) break
            if (change.uptimeMillis - down.uptimeMillis > SwipeMaxDurationMs) break
            if (!tracking && change.isConsumed) break

            total += change.positionChangeIgnoreConsumed()
            if (!tracking) {
                if (abs(total.x) < slop && abs(total.y) < slop) continue
                if (total.x >= 0 || abs(total.y) > abs(total.x)) break
                tracking = true
            }
            change.consume()
            if (-total.x >= triggerPx) {
                onSwipe()
                break
            }
        }
    }
}

/**
 * 왼쪽 스와이프 액션 행. 탭은 말풍선, 스와이프는 행 전체가 받는다 (iOS 셀과 동일).
 * 발동하면 0.3초에 말풍선이 나가고, 말풍선 끝에 붙은 75 폭 그라데이션이 함께 움직인다.
 */
@Composable
fun SwipeToActionCell(
    itemId: String,
    enabled: Boolean,
    gradientColor: Color,
    onAction: (String) -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val swipeX = remember(itemId) { Animatable(0f) }
    val gradientAlpha = remember(itemId) { Animatable(0f) }
    val density = LocalDensity.current
    val screenWidthPx = with(density) { LocalConfiguration.current.screenWidthDp.dp.toPx() }
    val backgroundColor = Flick.colors.bg
    val currentId by rememberUpdatedState(itemId)
    val currentEnabled by rememberUpdatedState(enabled)
    val currentAction by rememberUpdatedState(onAction)
    var completing by remember(itemId) { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .pointerInput(itemId) {
                detectLeftSwipe(isEnabled = { currentEnabled && !completing }) {
                    completing = true
                    scope.launch {
                        val slideOut = tween<Float>(SwipeAnimationMs, easing = EaseIn)
                        launch { gradientAlpha.animateTo(1f, slideOut) }
                        swipeX.animateTo(-screenWidthPx, slideOut)
                        currentAction(currentId)
                        delay(SwipeResetDelayMs)
                        swipeX.snapTo(0f)
                        gradientAlpha.snapTo(0f)
                        completing = false
                    }
                }
            }
            .then(modifier),
    ) {
        Box(modifier = Modifier.graphicsLayer { translationX = swipeX.value }) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .layout { measurable, constraints ->
                        val gradient = measurable.measure(
                            Constraints.fixed(SwipeGradientWidth.roundToPx(), constraints.maxHeight)
                        )
                        layout(constraints.maxWidth, constraints.maxHeight) {
                            gradient.place(constraints.maxWidth - SwipeGradientOverlap.roundToPx(), 0)
                        }
                    }
                    .graphicsLayer { alpha = gradientAlpha.value }
                    .background(Brush.horizontalGradient(listOf(gradientColor, backgroundColor)))
            )
            content()
        }
    }
}

private const val MemoLineSpacing = 5f

/**
 * 링크 부분만 파란 밑줄로 표시하는 메모 텍스트 (iOS highlightContainedLinks).
 * 표시 전용 — 더블탭·스와이프와 충돌하지 않도록 탭 핸들러를 달지 않고,
 * 링크는 메뉴의 "링크 열기"로만 연다.
 */
@Composable
fun LinkedText(
    text: String,
    fontSize: TextUnit,
    fontFamily: FontFamily,
    color: Color,
    modifier: Modifier = Modifier,
) {
    val linkColor = Flick.colors.link
    val annotated = remember(text, linkColor) {
        buildAnnotatedString {
            append(text)
            text.containedLinks().forEach { link ->
                addStyle(
                    SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline),
                    link.range.first,
                    link.range.last + 1,
                )
            }
        }
    }
    Text(
        annotated,
        fontSize = fontSize,
        fontFamily = fontFamily,
        color = color,
        // iOS setSpacing(spacing: 5): 줄 사이만 벌리고 한 줄 메모의 말풍선 높이는 그대로 둔다
        lineHeight = (fontSize.value + MemoLineSpacing).sp,
        style = LocalTextStyle.current.copy(
            lineHeightStyle = LineHeightStyle(
                alignment = LineHeightStyle.Alignment.Center,
                trim = LineHeightStyle.Trim.Both,
            ),
        ),
        modifier = modifier,
    )
}

/** 말풍선 공통 모양 */
val BubbleShape = RoundedCornerShape(8.dp)
val BubblePaddingH: Dp = 18.dp
val BubblePaddingV: Dp = 15.dp

/** iOS 스토리보드의 라벨 최대 너비 (width <= 270) */
val MemoMaxTextWidth: Dp = 270.dp

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
