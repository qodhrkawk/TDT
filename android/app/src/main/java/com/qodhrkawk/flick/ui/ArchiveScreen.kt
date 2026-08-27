package com.qodhrkawk.flick.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import kotlinx.coroutines.delay

/**
 * 아카이브: 날짜별 최신순. 왼쪽 스와이프로 원래 날짜에 복원.
 * 진입 시 헤더·셀이 오른쪽에서 슬라이드인 (섹션 +0.05초, 행 +0.02초).
 */
@Composable
fun ArchiveScreen(state: FlickAppState, active: Boolean, onBack: () -> Unit) {
    val colors = Flick.colors
    val listState = rememberLazyListState()
    var actionDialogId by remember { mutableStateOf<String?>(null) }
    var editDialogId by remember { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.fillMaxSize().background(colors.bg)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BackIcon(
                colors.mainText,
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onBack() },
            )
            Spacer(Modifier.width(8.dp))
            Text(
                "아카이브",
                fontSize = 18.sp,
                fontFamily = GmarketSans,
                fontWeight = FontWeight.Bold,
                color = colors.mainText,
            )
        }

        if (state.archiveSections.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    "완료한 할 일이 여기에 쌓여요.",
                    fontSize = 14.sp,
                    fontFamily = GmarketSans,
                    color = colors.subText,
                )
            }
        } else {
            LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                state.archiveSections.forEachIndexed { sectionIndex, section ->
                    item(key = "ah:${section.date}") {
                        SlideInOnEnter(active, sectionIndex, 0) {
                            Text(
                                section.date,
                                fontSize = 12.sp,
                                fontFamily = GmarketSans,
                                color = colors.archiveText,
                                modifier = Modifier.padding(start = 20.dp, top = 16.dp, bottom = 4.dp),
                            )
                        }
                    }
                    items(section.items, key = { "at:${it.id}" }) { todo ->
                        val rowIndex = section.items.indexOfFirst { it.id == todo.id } + 1
                        SlideInOnEnter(active, sectionIndex, rowIndex) {
                            ArchiveCell(
                                todo = todo,
                                onRestore = { state.restore(it) },
                                onDoubleTap = { state.archiveToggleImportant(it) },
                                onLongPress = { actionDialogId = it },
                            )
                        }
                    }
                }
                item(key = "afooter") { Spacer(Modifier.height(40.dp)) }
            }
        }
    }

    // 길게 누르기: 수정 / 삭제
    actionDialogId?.let { id ->
        val todo = state.findInArchive(id)
        if (todo == null) {
            actionDialogId = null
        } else {
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
                            state.archiveDelete(id)
                        }
                    }
                },
                confirmButton = {},
            )
        }
    }

    editDialogId?.let { id ->
        val todo = state.findInArchive(id)
        if (todo == null) {
            editDialogId = null
        } else {
            EditDialog(
                initialText = todo.todo,
                onCancel = { editDialogId = null },
                onSave = { text ->
                    editDialogId = null
                    if (text.isNotBlank()) state.archiveUpdateText(id, text)
                },
            )
        }
    }
}

/** 진입 시 오른쪽에서 슬라이드인. active가 될 때마다 다시 재생 */
@Composable
private fun SlideInOnEnter(
    active: Boolean,
    sectionIndex: Int,
    rowIndex: Int,
    content: @Composable () -> Unit,
) {
    val progress = remember { Animatable(if (active) 0f else 1f) }
    LaunchedEffect(active) {
        if (active) {
            progress.snapTo(1f)
            delay(sectionIndex * 50L + rowIndex * 20L)
            progress.animateTo(0f, tween(220))
        }
    }
    Box(
        modifier = Modifier.graphicsLayer {
            translationX = progress.value * size.width * 0.6f
            alpha = 1f - progress.value * 0.9f
        },
    ) {
        content()
    }
}

@Composable
private fun ArchiveCell(
    todo: TodoData,
    onRestore: (String) -> Unit,
    onDoubleTap: (String) -> Unit,
    onLongPress: (String) -> Unit,
) {
    val colors = Flick.colors
    SwipeToActionCell(
        itemId = todo.id,
        enabled = true,
        gradientColor = colors.theme,
        onAction = onRestore,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
    ) { gestureModifier ->
        Box(
            modifier = gestureModifier
                .pointerInput(todo.id) {
                    detectTapGestures(
                        onDoubleTap = { onDoubleTap(todo.id) },
                        onLongPress = { onLongPress(todo.id) },
                    )
                }
                .background(colors.archiveBox, BubbleShape)
                .then(
                    if (todo.isImportant)
                        Modifier.border(1.5.dp, colors.theme, BubbleShape)
                    else Modifier
                )
                .padding(horizontal = BubblePaddingH, vertical = BubblePaddingV),
        ) {
            Text(todo.todo, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.doneText)
        }
    }
}
