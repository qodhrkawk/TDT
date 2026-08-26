package com.qodhrkawk.flick.spike

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import kotlin.math.abs
import kotlinx.coroutines.launch

val ThemeColor = Color(0xFF0069CA)
val MainText = Color(0xFF191919)
val SubText = Color(0xFF8A8A8A)
val BubbleColor = Color(0xFFF2F3F5)

data class SpikeTodo(
    val id: Int,
    val date: String,
    val text: String,
    val isImportant: Boolean = false,
)

private fun today(): String = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy.MM.dd"))

class SpikeModel {
    var todos by mutableStateOf(seed())
    var pinned by mutableStateOf(
        listOf(
            SpikeTodo(100, "2026.08.20", "공과금 납부"),
            SpikeTodo(101, "2026.08.21", "건강검진 예약"),
        )
    )
    var pinnedCollapsed by mutableStateOf(false)

    private fun seed(): List<SpikeTodo> {
        var id = 0
        fun t(date: String, text: String) = SpikeTodo(id++, date, text)
        return listOf(
            t("2026.08.22", "장보기 목록 정리"),
            t("2026.08.22", "세탁소 옷 찾기"),
            t("2026.08.22", "도서관 책 반납"),
            t("2026.08.24", "부모님께 전화"),
            t("2026.08.24", "보험 서류 제출"),
            t("2026.08.24", "운동화 주문"),
            t(today(), "회의록 정리해서 공유"),
            t(today(), "스파이크 결과 정리"),
            t(today(), "우유 사기"),
            t(today(), "여행 숙소 예약"),
        )
    }

    // 섹션: 날짜별 그룹. 리스트 순서가 곧 섹션 순서이므로 groupBy(LinkedHashMap)로 충분
    fun sections(): List<Pair<String, List<SpikeTodo>>> =
        todos.groupBy { it.date }.map { it.key to it.value }

    fun find(id: Int): SpikeTodo? = todos.find { it.id == id } ?: pinned.find { it.id == id }

    fun toggleImportant(id: Int) {
        todos = todos.map { if (it.id == id) it.copy(isImportant = !it.isImportant) else it }
        pinned = pinned.map { if (it.id == id) it.copy(isImportant = !it.isImportant) else it }
    }

    fun delete(id: Int) {
        todos = todos.filterNot { it.id == id }
        pinned = pinned.filterNot { it.id == id }
    }

    fun complete(id: Int) = delete(id)

    fun isPinned(id: Int) = pinned.any { it.id == id }

    fun pin(id: Int) {
        val t = todos.find { it.id == id } ?: return
        todos = todos.filterNot { it.id == id }
        pinned = listOf(t) + pinned
    }

    // 원래 date 위치로 복귀. 같은 날짜 섹션 끝에, 없으면 날짜 오름차순 위치에 삽입
    fun unpin(id: Int) {
        val t = pinned.find { it.id == id } ?: return
        pinned = pinned.filterNot { it.id == id }
        val list = todos.toMutableList()
        val sameLast = list.indexOfLast { it.date == t.date }
        if (sameLast != -1) {
            list.add(sameLast + 1, t)
        } else {
            val after = list.indexOfFirst { it.date > t.date }
            if (after == -1) list.add(t) else list.add(after, t)
        }
        todos = list
    }

    // 드래그: 다른 항목 위를 지날 때. 대상 섹션의 date를 즉시 따라간다
    fun moveOverItem(id: Int, targetId: Int) {
        val list = todos.toMutableList()
        val from = list.indexOfFirst { it.id == id }
        val toOrig = list.indexOfFirst { it.id == targetId }
        if (from == -1 || toOrig == -1) return
        val item = list.removeAt(from)
        val targetIdx = list.indexOfFirst { it.id == targetId }
        val targetDate = list[targetIdx].date
        val insertAt = if (from < toOrig) targetIdx + 1 else targetIdx
        list.add(insertAt, item.copy(date = targetDate))
        todos = list
    }

    // 드래그: 헤더를 넘어갈 때. 아래로면 그 섹션 첫 번째, 위로면 이전 섹션 마지막이 된다
    fun moveOverHeader(id: Int, headerDate: String, movingDown: Boolean): Boolean {
        val list = todos.toMutableList()
        val from = list.indexOfFirst { it.id == id }
        if (from == -1) return false
        val item = list.removeAt(from)
        if (movingDown) {
            val idx = list.indexOfFirst { it.date >= headerDate }
            if (idx == -1) {
                list.add(item.copy(date = headerDate))
            } else {
                list.add(idx, item.copy(date = list[idx].date))
            }
        } else {
            val aboveIdx = list.indexOfLast { it.date < headerDate }
            if (aboveIdx == -1) {
                list.add(from, item)
                todos = list
                return false
            }
            list.add(aboveIdx + 1, item.copy(date = list[aboveIdx].date))
        }
        todos = list
        return true
    }
}

class DragState {
    var draggingId by mutableStateOf<Int?>(null)
    var offsetY by mutableFloatStateOf(0f)
    var moved by mutableStateOf(false)

    fun clear() {
        draggingId = null
        offsetY = 0f
        moved = false
    }
}

@Composable
fun SpikeScreen() {
    val model = remember { SpikeModel() }
    val drag = remember { DragState() }
    val listState = rememberLazyListState()
    val haptic = LocalHapticFeedback.current
    val touchSlop = LocalViewConfiguration.current.touchSlop
    var dialogTodoId by remember { mutableStateOf<Int?>(null) }

    // 드래그 로직: 셀에서 델타만 받아서 여기서 처리
    val onCellDragStart: (Int) -> Unit = { id ->
        drag.draggingId = id
        drag.offsetY = 0f
        drag.moved = false
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    val onCellDragBy: (Float) -> Unit = onCellDragBy@{ dy ->
        val id = drag.draggingId ?: return@onCellDragBy
        drag.offsetY += dy
        if (!drag.moved && abs(drag.offsetY) > touchSlop) drag.moved = true
        if (!drag.moved) return@onCellDragBy

        val info = listState.layoutInfo.visibleItemsInfo.find { it.key == "t:$id" }
            ?: return@onCellDragBy
        val center = info.offset + info.size / 2f + drag.offsetY
        val target = listState.layoutInfo.visibleItemsInfo.find {
            it.key != info.key && it.key != "footer" &&
                center >= it.offset && center < it.offset + it.size
        } ?: return@onCellDragBy
        val key = target.key as? String ?: return@onCellDragBy
        val movingDown = target.index > info.index

        if (key.startsWith("t:")) {
            model.moveOverItem(id, key.substring(2).toInt())
            drag.offsetY += if (movingDown) -target.size.toFloat() else target.size.toFloat()
        } else if (key.startsWith("h:")) {
            val ok = model.moveOverHeader(id, key.substring(2), movingDown)
            if (ok) {
                drag.offsetY += if (movingDown) -target.size.toFloat() else target.size.toFloat()
            }
        }
    }
    // 탭 감지기가 UP을 소비하면 end 대신 cancel이 오므로 둘을 동일하게 처리
    val onCellDragFinish: () -> Unit = {
        val id = drag.draggingId
        val moved = drag.moved
        android.util.Log.d("SPIKE", "dragFinish id=$id moved=$moved")
        drag.clear()
        if (id != null && !moved) dialogTodoId = id
    }

    // 앱 실행 시 오늘 섹션으로 자동 스크롤.
    // 첫 호출은 레이아웃 측정 전이라 오버스크롤될 수 있어 한 프레임 뒤 재호출로 보정
    LaunchedEffect(Unit) {
        val sections = model.sections()
        var index = 0
        for ((date, items) in sections) {
            if (date == today()) break
            index += 1 + items.size
        }
        listState.scrollToItem(index)
        androidx.compose.runtime.withFrameNanos { }
        listState.scrollToItem(index)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Text(
            "Flick Spike",
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = MainText,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
        )

        if (model.pinned.isNotEmpty()) {
            PinnedBar(model) { dialogTodoId = it }
        }

        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize()
        ) {
            model.sections().forEach { (date, items) ->
                item(key = "h:$date") {
                    Text(
                        date,
                        fontSize = 12.sp,
                        color = SubText,
                        modifier = Modifier
                            .animateItem()
                            .padding(start = 20.dp, top = 16.dp, bottom = 4.dp)
                    )
                }
                items(items, key = { "t:${it.id}" }) { todo ->
                    TodoCell(
                        todo = todo,
                        drag = drag,
                        onDoubleTap = { model.toggleImportant(todo.id) },
                        onComplete = { model.complete(todo.id) },
                        onDragStart = onCellDragStart,
                        onDragBy = onCellDragBy,
                        onDragFinish = onCellDragFinish,
                    )
                }
            }
            item(key = "footer") { Spacer(Modifier.height(80.dp)) }
        }
    }

    val dialogTodo = dialogTodoId?.let { model.find(it) }
    if (dialogTodo != null) {
        val pinned = model.isPinned(dialogTodo.id)
        AlertDialog(
            onDismissRequest = { dialogTodoId = null },
            title = { Text(dialogTodo.text, fontSize = 15.sp) },
            text = {
                Column {
                    TextButton(onClick = { dialogTodoId = null }) { Text("수정") }
                    TextButton(onClick = {
                        model.delete(dialogTodo.id); dialogTodoId = null
                    }) { Text("삭제", color = Color(0xFFD94A2A)) }
                    TextButton(onClick = {
                        if (pinned) model.unpin(dialogTodo.id) else model.pin(dialogTodo.id)
                        dialogTodoId = null
                    }) { Text(if (pinned) "고정 해제" else "고정") }
                    TextButton(onClick = { dialogTodoId = null }) { Text("선택") }
                }
            },
            confirmButton = {},
        )
    }
}

@Composable
private fun androidx.compose.foundation.lazy.LazyItemScope.TodoCell(
    todo: SpikeTodo,
    drag: DragState,
    onDoubleTap: () -> Unit,
    onComplete: () -> Unit,
    onDragStart: (Int) -> Unit,
    onDragBy: (Float) -> Unit,
    onDragFinish: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val swipeX = remember { Animatable(0f) }
    val density = LocalDensity.current
    val screenWidthPx = with(density) { LocalConfiguration.current.screenWidthDp.dp.toPx() }
    val thresholdPx = with(density) { 100.dp.toPx() }
    val isDragging = drag.draggingId == todo.id

    Box(
        modifier = Modifier
            .then(if (isDragging) Modifier else Modifier.animateItem())
            .zIndex(if (isDragging) 1f else 0f)
            .graphicsLayer {
                translationY = if (drag.draggingId == todo.id) drag.offsetY else 0f
                shadowElevation = if (drag.draggingId == todo.id) 16f else 0f
            }
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
    ) {
        Box(
            modifier = Modifier
                .graphicsLayer { translationX = swipeX.value }
                .pointerInput(todo.id) {
                    detectTapGestures(onDoubleTap = { onDoubleTap() })
                }
                // 셀(안쪽)에 걸어야 리스트 스크롤보다 먼저 이동량을 소비한다
                .pointerInput(todo.id) {
                    detectDragGesturesAfterLongPress(
                        onDragStart = { onDragStart(todo.id) },
                        onDrag = { change, amount ->
                            change.consume()
                            onDragBy(amount.y)
                        },
                        onDragEnd = { onDragFinish() },
                        onDragCancel = { onDragFinish() },
                    )
                }
                .pointerInput(todo.id) {
                    detectHorizontalDragGestures(
                        onHorizontalDrag = { change, amount ->
                            change.consume()
                            scope.launch {
                                swipeX.snapTo((swipeX.value + amount).coerceIn(-screenWidthPx, 0f))
                            }
                        },
                        onDragEnd = {
                            scope.launch {
                                if (swipeX.value < -thresholdPx) {
                                    swipeX.animateTo(-screenWidthPx, tween(300))
                                    onComplete()
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
                .background(BubbleColor, RoundedCornerShape(8.dp))
                .then(
                    if (todo.isImportant)
                        Modifier.border(1.5.dp, ThemeColor, RoundedCornerShape(8.dp))
                    else Modifier
                )
                .padding(horizontal = 18.dp, vertical = 15.dp)
        ) {
            Text(todo.text, fontSize = 15.sp, color = MainText)
        }
        // 스와이프 진행에 따라 우측 그라데이션
        Box(
            modifier = Modifier
                .matchParentSize()
                .graphicsLayer { alpha = (-swipeX.value / thresholdPx).coerceIn(0f, 1f) }
                .background(
                    Brush.horizontalGradient(
                        listOf(Color.Transparent, ThemeColor.copy(alpha = 0.3f))
                    )
                )
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun PinnedBar(model: SpikeModel, onLongPress: (Int) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFFEFF4FA))
            .padding(vertical = 6.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { model.pinnedCollapsed = !model.pinnedCollapsed }
                .padding(horizontal = 20.dp, vertical = 6.dp)
        ) {
            Text(
                "고정됨 ${model.pinned.size}",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = ThemeColor,
            )
        }
        if (!model.pinnedCollapsed) {
            model.pinned.forEach { todo ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .combinedClickable(
                                onClick = {},
                                onLongClick = { onLongPress(todo.id) },
                            )
                            .background(Color.White, RoundedCornerShape(8.dp))
                            .then(
                                if (todo.isImportant)
                                    Modifier.border(1.5.dp, ThemeColor, RoundedCornerShape(8.dp))
                                else Modifier
                            )
                            .padding(horizontal = 18.dp, vertical = 15.dp)
                    ) {
                        Text(todo.text, fontSize = 15.sp, color = MainText)
                    }
                }
            }
        }
    }
}
