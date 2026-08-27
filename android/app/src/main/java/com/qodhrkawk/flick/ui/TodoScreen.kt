package com.qodhrkawk.flick.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import kotlin.math.abs
import kotlinx.coroutines.launch

class DragState {
    var draggingId by mutableStateOf<String?>(null)
    var offsetY by mutableFloatStateOf(0f)
    var moved by mutableStateOf(false)

    fun clear() {
        draggingId = null
        offsetY = 0f
        moved = false
    }
}

@Composable
fun TodoScreen(
    state: FlickAppState,
    onOpenSettings: () -> Unit,
    onOpenArchive: () -> Unit,
) {
    val colors = Flick.colors
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val haptic = LocalHapticFeedback.current
    val touchSlop = LocalViewConfiguration.current.touchSlop
    val drag = remember { DragState() }

    var inputText by remember { mutableStateOf("") }
    var selectionMode by remember { mutableStateOf(false) }
    val selectedIds = remember { mutableStateListOf<String>() }
    var actionDialogId by remember { mutableStateOf<String?>(null) }
    var editDialogId by remember { mutableStateOf<String?>(null) }
    var showBatchDeleteConfirm by remember { mutableStateOf(false) }

    fun exitSelection() {
        selectionMode = false
        selectedIds.clear()
    }

    fun rowCountBeforeToday(): Int {
        var index = 0
        for (section in state.sections) {
            if (section.date == todayString()) return index
            index += 1 + section.items.size
        }
        return index
    }

    // 앱 실행 시 오늘 섹션으로 자동 스크롤 (레이아웃 전 오버스크롤 보정 포함)
    LaunchedEffect(Unit) {
        val index = rowCountBeforeToday()
        listState.scrollToItem(index)
        withFrameNanos { }
        listState.scrollToItem(index)
    }

    // 드래그 로직 — 스파이크 검증 패턴 그대로
    val onCellDragStart: (String) -> Unit = start@{ id ->
        if (selectionMode) return@start
        drag.draggingId = id
        drag.offsetY = 0f
        drag.moved = false
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    val onCellDragBy: (Float) -> Unit = dragBy@{ dy ->
        val id = drag.draggingId ?: return@dragBy
        drag.offsetY += dy
        if (!drag.moved && abs(drag.offsetY) > touchSlop) drag.moved = true
        if (!drag.moved) return@dragBy

        val info = listState.layoutInfo.visibleItemsInfo.find { it.key == "t:$id" } ?: return@dragBy
        val center = info.offset + info.size / 2f + drag.offsetY
        val target = listState.layoutInfo.visibleItemsInfo.find {
            it.key != info.key && it.key != "footer" &&
                center >= it.offset && center < it.offset + it.size
        } ?: return@dragBy
        val key = target.key as? String ?: return@dragBy
        val movingDown = target.index > info.index

        if (key.startsWith("t:")) {
            state.moveOverItem(id, key.substring(2))
            drag.offsetY += if (movingDown) -target.size.toFloat() else target.size.toFloat()
        } else if (key.startsWith("h:")) {
            if (state.moveOverHeader(id, key.substring(2), movingDown)) {
                drag.offsetY += if (movingDown) -target.size.toFloat() else target.size.toFloat()
            }
        }
    }
    // 탭 감지기가 UP을 소비하면 end 대신 cancel이 오므로 동일 처리 (스파이크 함정 2)
    val onCellDragFinish: () -> Unit = {
        val id = drag.draggingId
        val moved = drag.moved
        drag.clear()
        if (id != null && !moved && !selectionMode) actionDialogId = id
    }

    Column(modifier = Modifier.fillMaxSize().background(colors.bg)) {
        // 헤더: 로고(탭 → 설정) + 아카이브 버튼
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "Flick",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = GmarketSans,
                color = colors.theme,
                modifier = Modifier.clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { onOpenSettings() },
            )
            Spacer(Modifier.weight(1f))
            ArchiveIcon(
                color = colors.mainText,
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onOpenArchive() },
            )
        }

        if (state.pinned.isNotEmpty()) {
            PinnedBar(state, onLongPress = { actionDialogId = it })
        }

        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxWidth().weight(1f),
        ) {
            state.sections.forEach { section ->
                item(key = "h:${section.date}") {
                    Text(
                        section.date,
                        fontSize = 12.sp,
                        fontFamily = GmarketSans,
                        color = colors.subText,
                        modifier = Modifier
                            .animateItem()
                            .padding(start = 20.dp, top = 16.dp, bottom = 4.dp),
                    )
                }
                items(section.items, key = { "t:${it.id}" }) { todo ->
                    TodoCell(
                        todo = todo,
                        drag = drag,
                        selectionMode = selectionMode,
                        checked = selectedIds.contains(todo.id),
                        onSelectTap = { id ->
                            if (selectedIds.contains(id)) selectedIds.remove(id) else selectedIds.add(id)
                        },
                        onDoubleTap = { state.toggleImportant(it) },
                        onComplete = { state.complete(it) },
                        onDragStart = onCellDragStart,
                        onDragBy = onCellDragBy,
                        onDragFinish = onCellDragFinish,
                    )
                }
            }
            item(key = "footer") { Spacer(Modifier.height(24.dp)) }
        }

        if (selectionMode) {
            SelectionBar(
                count = selectedIds.size,
                onCancel = { exitSelection() },
                onComplete = {
                    state.batchComplete(selectedIds.toList())
                    exitSelection()
                },
                onDelete = { showBatchDeleteConfirm = true },
            )
        } else {
            InputBar(
                text = inputText,
                onTextChange = { inputText = it },
                onSend = {
                    if (inputText.isNotBlank()) {
                        state.add(inputText)
                        inputText = ""
                        scope.launch {
                            val total = state.sections.sumOf { 1 + it.items.size } + 1
                            listState.animateScrollToItem(total - 1)
                        }
                    }
                },
            )
        }
    }

    // 길게 누르기 다이얼로그: 수정 / 삭제 / 고정(해제) / 선택
    actionDialogId?.let { id ->
        val todo = state.find(id)
        if (todo == null) {
            actionDialogId = null
        } else {
            val pinned = state.isPinned(id)
            AlertDialog(
                onDismissRequest = { actionDialogId = null },
                containerColor = colors.box,
                title = {
                    Text(todo.todo, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
                },
                text = {
                    Column {
                        DialogAction("수정", colors.theme) {
                            actionDialogId = null
                            editDialogId = id
                        }
                        DialogAction("삭제", colors.alert) {
                            actionDialogId = null
                            state.delete(id)
                        }
                        DialogAction(if (pinned) "고정 해제" else "고정", colors.theme) {
                            actionDialogId = null
                            if (pinned) state.unpin(id) else state.pin(id)
                        }
                        if (!pinned) {
                            DialogAction("선택", colors.theme) {
                                actionDialogId = null
                                selectionMode = true
                                selectedIds.clear()
                                selectedIds.add(id)
                            }
                        }
                    }
                },
                confirmButton = {},
            )
        }
    }

    // 수정 다이얼로그
    editDialogId?.let { id ->
        val todo = state.find(id)
        if (todo == null) {
            editDialogId = null
        } else {
            EditDialog(
                initialText = todo.todo,
                onCancel = { editDialogId = null },
                onSave = { text ->
                    editDialogId = null
                    if (text.isNotBlank()) state.updateText(id, text)
                },
            )
        }
    }

    // 일괄 삭제 확인 알럿 (1회)
    if (showBatchDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showBatchDeleteConfirm = false },
            containerColor = colors.box,
            title = {
                Text(
                    "${selectedIds.size}개의 할 일을 삭제할까요?",
                    fontSize = 15.sp,
                    fontFamily = GmarketSans,
                    color = colors.mainText,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showBatchDeleteConfirm = false
                    state.batchDelete(selectedIds.toList())
                    exitSelection()
                }) { Text("삭제", color = colors.alert, fontFamily = GmarketSans) }
            },
            dismissButton = {
                TextButton(onClick = { showBatchDeleteConfirm = false }) {
                    Text("취소", color = colors.subText, fontFamily = GmarketSans)
                }
            },
        )
    }
}

@Composable
fun DialogAction(label: String, color: Color, onClick: () -> Unit) {
    Text(
        label,
        fontSize = 15.sp,
        fontFamily = GmarketSans,
        color = color,
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp),
    )
}

@Composable
fun EditDialog(initialText: String, onCancel: () -> Unit, onSave: (String) -> Unit) {
    val colors = Flick.colors
    var text by remember { mutableStateOf(initialText) }
    AlertDialog(
        onDismissRequest = onCancel,
        containerColor = colors.box,
        text = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(colors.textBox, BubbleShape)
                    .padding(horizontal = 14.dp, vertical = 12.dp),
            ) {
                BasicTextField(
                    value = text,
                    onValueChange = { text = it },
                    textStyle = TextStyle(
                        fontSize = 15.sp,
                        fontFamily = GmarketSans,
                        color = colors.typingText,
                    ),
                    cursorBrush = SolidColor(colors.theme),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { onSave(text) }) {
                Text("저장", color = colors.theme, fontFamily = GmarketSans)
            }
        },
        dismissButton = {
            TextButton(onClick = onCancel) {
                Text("취소", color = colors.subText, fontFamily = GmarketSans)
            }
        },
    )
}

@Composable
private fun PinnedBar(state: FlickAppState, onLongPress: (String) -> Unit) {
    val colors = Flick.colors
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.theme.copy(alpha = if (colors.isDark) 0.14f else 0.08f))
            .padding(vertical = 6.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { state.togglePinnedCollapsed() }
                .padding(horizontal = 20.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "고정됨 ${state.pinned.size}",
                fontSize = 14.sp,
                fontFamily = GmarketSans,
                fontWeight = FontWeight.Medium,
                color = colors.theme,
            )
            Spacer(Modifier.width(6.dp))
            ChevronIcon(colors.theme, expanded = !state.pinnedCollapsed, modifier = Modifier.size(14.dp))
        }
        if (!state.pinnedCollapsed) {
            state.pinned.forEach { todo ->
                // 스와이프 완료 히트 영역은 행 전체 (말풍선 오른쪽 빈 곳 포함)
                SwipeToActionCell(
                    itemId = todo.id,
                    enabled = true,
                    gradientColor = colors.theme,
                    onAction = { state.complete(it) },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                ) { gestureModifier ->
                    Box(
                        modifier = gestureModifier
                            .fillMaxWidth()
                            .pointerInput(todo.id) {
                                detectTapGestures(onLongPress = { onLongPress(todo.id) })
                            },
                    ) {
                        Box(
                            modifier = Modifier
                                .background(colors.box, BubbleShape)
                                .then(
                                    if (todo.isImportant)
                                        Modifier.border(1.5.dp, colors.theme, BubbleShape)
                                    else Modifier
                                )
                                .padding(horizontal = BubblePaddingH, vertical = BubblePaddingV),
                        ) {
                            Text(
                                todo.todo,
                                fontSize = 15.sp,
                                fontFamily = GmarketSans,
                                color = colors.mainText,
                                modifier = Modifier.padding(end = 18.dp),
                            )
                            PinIcon(
                                colors.theme,
                                modifier = Modifier
                                    .size(14.dp)
                                    .align(Alignment.TopEnd),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.lazy.LazyItemScope.TodoCell(
    todo: TodoData,
    drag: DragState,
    selectionMode: Boolean,
    checked: Boolean,
    onSelectTap: (String) -> Unit,
    onDoubleTap: (String) -> Unit,
    onComplete: (String) -> Unit,
    onDragStart: (String) -> Unit,
    onDragBy: (Float) -> Unit,
    onDragFinish: () -> Unit,
) {
    val colors = Flick.colors
    val isDragging = drag.draggingId == todo.id

    Row(
        modifier = Modifier
            .then(if (isDragging) Modifier else Modifier.animateItem())
            .zIndex(if (isDragging) 1f else 0f)
            .graphicsLayer {
                translationY = if (drag.draggingId == todo.id) drag.offsetY else 0f
                shadowElevation = if (drag.draggingId == todo.id) 16f else 0f
            }
            .fillMaxWidth()
            .then(
                if (selectionMode) Modifier.clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { onSelectTap(todo.id) }
                else Modifier
            )
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (selectionMode) {
            CheckCircle(
                checked = checked,
                color = colors.theme,
                inactive = colors.inactive,
                modifier = Modifier.size(22.dp),
            )
            Spacer(Modifier.width(10.dp))
        }

        SwipeToActionCell(
            itemId = todo.id,
            enabled = !selectionMode,
            gradientColor = colors.theme,
            onAction = onComplete,
        ) { gestureModifier ->
            Box(
                modifier = gestureModifier
                    .pointerInput(todo.id, selectionMode) {
                        if (!selectionMode) {
                            detectTapGestures(onDoubleTap = { onDoubleTap(todo.id) })
                        }
                    }
                    // 셀(안쪽)에 걸어야 리스트 스크롤보다 먼저 이동량을 소비한다 (스파이크 함정 1)
                    .pointerInput(todo.id, selectionMode) {
                        if (!selectionMode) {
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
                    }
                    .background(colors.box, BubbleShape)
                    .then(
                        if (todo.isImportant)
                            Modifier.border(1.5.dp, colors.theme, BubbleShape)
                        else Modifier
                    )
                    .padding(horizontal = BubblePaddingH, vertical = BubblePaddingV),
            ) {
                Text(todo.todo, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
            }
        }
    }
}

@Composable
private fun InputBar(text: String, onTextChange: (String) -> Unit, onSend: () -> Unit) {
    val colors = Flick.colors
    val active = text.isNotBlank()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.bg)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .background(colors.textBox, BubbleShape)
                .padding(horizontal = 14.dp, vertical = 13.dp),
        ) {
            if (text.isEmpty()) {
                Text("할 일 입력", fontSize = 15.sp, fontFamily = GmarketSans, color = colors.inactive)
            }
            BasicTextField(
                value = text,
                onValueChange = onTextChange,
                textStyle = TextStyle(
                    fontSize = 15.sp,
                    fontFamily = GmarketSans,
                    color = colors.typingText,
                ),
                cursorBrush = SolidColor(colors.theme),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.width(10.dp))
        Box(
            modifier = Modifier
                .size(44.dp)
                .background(if (active) colors.theme else colors.inactive, BubbleShape)
                .clickable(enabled = active) { onSend() },
            contentAlignment = Alignment.Center,
        ) {
            SendIcon(Color.White, modifier = Modifier.size(22.dp))
        }
    }
}

@Composable
private fun SelectionBar(
    count: Int,
    onCancel: () -> Unit,
    onComplete: () -> Unit,
    onDelete: () -> Unit,
) {
    val colors = Flick.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.bg)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "취소",
            fontSize = 15.sp,
            fontFamily = GmarketSans,
            color = colors.subText,
            modifier = Modifier.clickable { onCancel() },
        )
        Text(
            "완료 $count",
            fontSize = 15.sp,
            fontFamily = GmarketSans,
            fontWeight = FontWeight.Medium,
            color = if (count > 0) Flick.colors.theme else colors.inactive,
            modifier = Modifier.clickable(enabled = count > 0) { onComplete() },
        )
        Text(
            "삭제 $count",
            fontSize = 15.sp,
            fontFamily = GmarketSans,
            fontWeight = FontWeight.Medium,
            color = if (count > 0) colors.alert else colors.inactive,
            modifier = Modifier.clickable(enabled = count > 0) { onDelete() },
        )
    }
}
