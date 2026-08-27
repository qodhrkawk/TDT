package com.qodhrkawk.flick.ui

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
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
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import com.qodhrkawk.flick.ui.theme.GmarketSansLight
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
    active: Boolean,
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
    var menuTarget by remember { mutableStateOf<MenuTarget?>(null) }
    var showBatchDeleteConfirm by remember { mutableStateOf(false) }

    fun exitSelection() {
        selectionMode = false
        selectedIds.clear()
    }

    fun openMenu(id: String) {
        val todo = state.find(id) ?: return
        val pinned = state.isPinned(id)
        menuTarget = MenuTarget(
            id = id,
            text = todo.todo,
            showPin = true,
            isPinned = pinned,
            showSelect = !pinned,
        )
    }

    // 앱 실행 시 오늘 섹션으로 자동 스크롤 (레이아웃 전 오버스크롤 보정 포함)
    LaunchedEffect(Unit) {
        var index = 0
        for (section in state.sections) {
            if (section.date == todayString()) break
            index += 1 + section.items.size
        }
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
    val onCellDragFinish: () -> Unit = { drag.clear() }

    Box(modifier = Modifier.fillMaxSize()) {
    Column(modifier = Modifier.fillMaxSize().background(colors.bg)) {
        // 헤더: [로고][더보기] ... [아카이브] — iOS Todo.storyboard 배치
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                painterResource(R.drawable.img_logo),
                contentDescription = "Flick",
                colorFilter = ColorFilter.tint(colors.theme),
                modifier = Modifier
                    .size(width = 72.dp, height = 25.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onOpenSettings() },
            )
            Spacer(Modifier.width(16.dp))
            Image(
                painterResource(R.drawable.btn_more),
                contentDescription = "설정",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onOpenSettings() },
            )
            Spacer(Modifier.weight(1f))
            Image(
                painterResource(R.drawable.btn_archive),
                contentDescription = "아카이브",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onOpenArchive() },
            )
        }

        if (state.pinned.isNotEmpty()) {
            PinnedBar(
                state = state,
                selectionMode = selectionMode,
                onTapBubble = { id ->
                    val todo = state.find(id) ?: return@PinnedBar
                    menuTarget = MenuTarget(id, todo.todo, showPin = true, isPinned = true)
                },
            )
        }

        Box(Modifier.fillMaxWidth().weight(1f)) {
            if (state.sections.isEmpty()) {
                EmptyPlaceholder(
                    imageRes = if (colors.isDark) R.drawable.img_empty_main_dark else R.drawable.img_empty_main,
                    text = "할 일을 모두 완료했어요!",
                )
            }
            LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                state.sections.forEachIndexed { sectionIndex, section ->
                    item(key = "h:${section.date}") {
                        Box(
                            modifier = Modifier
                                .animateItem()
                                .fillMaxWidth()
                                .height(if (sectionIndex == 0) 80.dp else 30.dp),
                            contentAlignment = Alignment.BottomStart,
                        ) {
                            EnterSlide(active, sectionIndex, 0, fromRight = true) {
                                Text(
                                    section.date,
                                    fontSize = 12.sp,
                                    fontFamily = GmarketSansLight,
                                    color = colors.subText,
                                    modifier = Modifier.padding(start = 20.dp),
                                )
                            }
                        }
                    }
                    items(section.items, key = { "t:${it.id}" }) { todo ->
                        val rowIndex = section.items.indexOfFirst { it.id == todo.id } + 1
                        val dragging = drag.draggingId == todo.id
                        Box(
                            modifier = Modifier
                                .then(if (dragging) Modifier else Modifier.animateItem())
                                .zIndex(if (dragging) 1f else 0f),
                        ) {
                            EnterSlide(active, sectionIndex, rowIndex, fromRight = true) {
                            TodoCell(
                                todo = todo,
                                drag = drag,
                                selectionMode = selectionMode,
                                checked = selectedIds.contains(todo.id),
                                menuOpen = menuTarget?.id == todo.id,
                                onSelectTap = { id ->
                                    if (selectedIds.contains(id)) selectedIds.remove(id) else selectedIds.add(id)
                                },
                                onTap = { openMenu(it) },
                                onDoubleTap = { state.toggleImportant(it) },
                                onComplete = { state.complete(it) },
                                onDragStart = onCellDragStart,
                                onDragBy = onCellDragBy,
                                onDragFinish = onCellDragFinish,
                            )
                            }
                        }
                    }
                }
                item(key = "footer") { Spacer(Modifier.height(24.dp)) }
            }
        }

        if (selectionMode) {
            SelectionBar(
                count = selectedIds.size,
                onCancel = { exitSelection() },
                onComplete = {
                    state.batchComplete(selectedIds.toList())
                    exitSelection()
                    state.showToast("완료되었어요")
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

    // 셀 탭 메뉴 (iOS AlertViewController)
    FlickActionMenu(
        target = menuTarget,
        onDismiss = { menuTarget = null },
        onPinToggle = { id -> if (state.isPinned(id)) state.unpin(id) else state.pin(id) },
        onSelect = { id ->
            selectionMode = true
            selectedIds.clear()
            selectedIds.add(id)
        },
        onEdit = { id, text ->
            state.updateText(id, text)
            state.showToast("수정되었어요")
        },
        onDelete = { id ->
            state.delete(id)
            state.showToast("삭제되었어요.")
        },
    )

    // 일괄 삭제 확인
    if (showBatchDeleteConfirm) {
        BatchDeleteConfirm(
            count = selectedIds.size,
            onCancel = { showBatchDeleteConfirm = false },
            onConfirm = {
                showBatchDeleteConfirm = false
                state.batchDelete(selectedIds.toList())
                exitSelection()
                state.showToast("삭제되었어요.")
            },
        )
    }
    }
}

@Composable
fun EmptyPlaceholder(imageRes: Int, text: String) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(painterResource(imageRes), contentDescription = null, modifier = Modifier.size(36.dp))
        Spacer(Modifier.height(10.dp))
        Text(text, fontSize = 15.sp, fontFamily = GmarketSans, color = Flick.colors.subText)
    }
}

@Composable
private fun BatchDeleteConfirm(count: Int, onCancel: () -> Unit, onConfirm: () -> Unit) {
    val colors = Flick.colors
    Box(Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.6f))) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(20.dp)
                .background(colors.box, BubbleShape)
                .padding(20.dp),
        ) {
            Text(
                "${count}개의 메모를 삭제할까요?",
                fontSize = 16.sp,
                fontFamily = GmarketSans,
                color = colors.mainText,
                modifier = Modifier.padding(vertical = 16.dp),
            )
            Row {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .background(colors.typingText.copy(alpha = 0.08f), BubbleShape)
                        .clickable { onCancel() },
                    contentAlignment = Alignment.Center,
                ) { Text("취소", fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText) }
                Spacer(Modifier.width(10.dp))
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .background(colors.theme, BubbleShape)
                        .clickable { onConfirm() },
                    contentAlignment = Alignment.Center,
                ) { Text("삭제", fontSize = 15.sp, fontFamily = GmarketSans, color = androidx.compose.ui.graphics.Color.White) }
            }
        }
    }
}

@Composable
private fun PinnedBar(
    state: FlickAppState,
    selectionMode: Boolean,
    onTapBubble: (String) -> Unit,
) {
    val colors = Flick.colors
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        // 헤더: 핀 아이콘 + "고정됨 N" + 셰브론, 전부 subText (iOS makePinnedToggleRow)
        Row(
            modifier = Modifier
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { state.togglePinnedCollapsed() }
                .padding(horizontal = 20.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PinIcon(colors.subText, modifier = Modifier.size(10.dp))
            Spacer(Modifier.width(5.dp))
            Text(
                "고정됨 ${state.pinned.size}",
                fontSize = 12.sp,
                fontFamily = GmarketSansLight,
                color = colors.subText,
            )
            Spacer(Modifier.width(5.dp))
            ChevronIcon(colors.subText, expanded = !state.pinnedCollapsed, modifier = Modifier.size(10.dp))
        }
        if (!state.pinnedCollapsed) {
            state.pinned.forEach { todo ->
                // 탭은 말풍선, 스와이프는 행 전체 (iOS makePinnedRow)
                SwipeToActionCell(
                    itemId = todo.id,
                    enabled = !selectionMode,
                    gradientColor = colors.theme,
                    onAction = { state.complete(it) },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                ) { gestureModifier ->
                    Box(modifier = gestureModifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier
                                .pointerInput(todo.id) {
                                    detectTapGestures(onTap = { onTapBubble(todo.id) })
                                }
                                .background(colors.box, BubbleShape)
                                .border(1.dp, colors.theme, BubbleShape)
                                .padding(horizontal = 12.dp, vertical = 11.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(Modifier.size(12.dp).graphicsLayer { rotationZ = 45f }) {
                                PinIcon(colors.theme, modifier = Modifier.size(12.dp))
                            }
                            Spacer(Modifier.width(7.dp))
                            Text(
                                todo.todo,
                                fontSize = 14.sp,
                                fontFamily = GmarketSans,
                                color = colors.mainText,
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TodoCell(
    todo: TodoData,
    drag: DragState,
    selectionMode: Boolean,
    checked: Boolean,
    menuOpen: Boolean,
    onSelectTap: (String) -> Unit,
    onTap: (String) -> Unit,
    onDoubleTap: (String) -> Unit,
    onComplete: (String) -> Unit,
    onDragStart: (String) -> Unit,
    onDragBy: (Float) -> Unit,
    onDragFinish: () -> Unit,
) {
    val colors = Flick.colors
    val isDragging = drag.draggingId == todo.id
    // 메뉴가 열린 동안 말풍선 하이라이트 (iOS wasSingleTapped → archiveBoxColor)
    val bubbleColor = if (menuOpen) colors.archiveBox else colors.box

    Box(
        modifier = Modifier
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
            ),
    ) {
        SwipeToActionCell(
            itemId = todo.id,
            enabled = !selectionMode,
            gradientColor = colors.theme,
            onAction = onComplete,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
        ) { gestureModifier ->
            Box(
                modifier = gestureModifier
                    .pointerInput(todo.id, selectionMode) {
                        if (!selectionMode) {
                            detectTapGestures(
                                onTap = { onTap(todo.id) },
                                onDoubleTap = { onDoubleTap(todo.id) },
                            )
                        }
                    }
                    // 셀(안쪽)에 걸어야 리스트 스크롤보다 먼저 이동량을 소비한다
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
                    .background(bubbleColor, BubbleShape)
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
        if (selectionMode) {
            CheckCircle(
                checked = checked,
                color = colors.theme,
                inactive = colors.inactive,
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .padding(end = 20.dp)
                    .size(24.dp),
            )
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
            .background(colors.box)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .background(colors.textBox, BubbleShape)
                .border(1.dp, colors.bg, BubbleShape)
                .padding(start = 14.dp, end = 44.dp, top = 13.dp, bottom = 13.dp),
        ) {
            if (text.isEmpty()) {
                Text(
                    "해야 할 일을 입력해주세요.",
                    fontSize = 15.sp,
                    fontFamily = GmarketSans,
                    color = colors.inactive,
                )
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
        Image(
            painterResource(R.drawable.btn_send_inactive),
            contentDescription = "전송",
            colorFilter = ColorFilter.tint(if (active) colors.theme else colors.inactive),
            modifier = Modifier
                .size(40.dp)
                .clickable(
                    enabled = active,
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { onSend() },
        )
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
            .background(colors.box)
            .padding(horizontal = 16.dp, vertical = 16.dp),
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
            color = if (count > 0) colors.theme else colors.inactive,
            modifier = Modifier.clickable(enabled = count > 0) { onComplete() },
        )
        Text(
            "삭제 $count",
            fontSize = 15.sp,
            fontFamily = GmarketSans,
            color = if (count > 0) colors.alert else colors.inactive,
            modifier = Modifier.clickable(enabled = count > 0) { onDelete() },
        )
    }
}
