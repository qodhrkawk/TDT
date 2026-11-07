package com.qodhrkawk.flick.ui

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.data.TodoData
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import com.qodhrkawk.flick.ui.theme.GmarketSansLight

/**
 * 아카이브 (페이저 왼쪽 페이지): 날짜별 최신순, 왼쪽 스와이프 = 원래 날짜로 복원.
 * 진입 시 왼쪽에서 슬라이드인 (메인과 반대 방향 — iOS와 동일).
 */
@Composable
fun ArchiveScreen(state: FlickAppState, active: Boolean, onBack: () -> Unit) {
    val colors = Flick.colors
    val listState = rememberLazyListState()
    var menuTarget by remember { mutableStateOf<MenuTarget?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
    Column(modifier = Modifier.fillMaxSize().background(colors.bg)) {
        // 헤더: imgArchive 타이틀 (왼쪽) + btnMain(오늘 할 일로) (오른쪽)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                painterResource(R.drawable.img_archive),
                contentDescription = "아카이브",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier.height(25.dp),
            )
            Spacer(Modifier.weight(1f))
            Image(
                painterResource(R.drawable.btn_main),
                contentDescription = "오늘 할 일",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onBack() },
            )
        }

        Box(Modifier.fillMaxSize()) {
            if (state.archiveSections.isEmpty()) {
                EmptyPlaceholder(
                    imageRes = if (colors.isDark) R.drawable.img_empty_archive_dark else R.drawable.img_empty_archive,
                    text = "앗, 아직 한 일들이 없네요!",
                )
            }
            LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                state.archiveSections.forEachIndexed { sectionIndex, section ->
                    val isTodaySection = section.date == todayString()
                    item(key = "ah:${section.date}") {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(if (sectionIndex == 0) 80.dp else 30.dp),
                            contentAlignment = Alignment.BottomStart,
                        ) {
                            EnterSlide(active, sectionIndex, 0, fromRight = false) {
                                Text(
                                    "${section.date} 한 일",
                                    fontSize = 12.sp,
                                    fontFamily = GmarketSansLight,
                                    color = if (isTodaySection) colors.theme else colors.subText,
                                    modifier = Modifier.padding(start = 20.dp),
                                )
                            }
                        }
                    }
                    items(section.items, key = { "at:${it.id}" }) { todo ->
                        val rowIndex = section.items.indexOfFirst { it.id == todo.id } + 1
                        EnterSlide(active, sectionIndex, rowIndex, fromRight = false) {
                            ArchiveCell(
                                todo = todo,
                                isToday = isTodaySection,
                                menuOpen = menuTarget?.id == todo.id,
                                onRestore = { state.restore(it) },
                                onDoubleTap = { state.archiveToggleImportant(it) },
                                onTap = { id ->
                                    val item = state.findInArchive(id) ?: return@ArchiveCell
                                    menuTarget = MenuTarget(id, item.todo, fromArchive = true)
                                },
                            )
                        }
                    }
                }
                item(key = "afooter") { Spacer(Modifier.height(40.dp)) }
            }
        }
    }

    FlickActionMenu(
        target = menuTarget,
        onDismiss = { menuTarget = null },
        onPinToggle = {},
        onSelect = {},
        onEdit = { id, text ->
            state.archiveUpdateText(id, text)
            state.showToast("수정되었어요")
        },
        onDelete = { id ->
            state.archiveDelete(id)
            state.showToast("삭제되었어요.")
        },
        onLinkOpenFailed = { state.showToast(LinkOpenFailedMessage) },
    )
    }
}

@Composable
private fun ArchiveCell(
    todo: TodoData,
    isToday: Boolean,
    menuOpen: Boolean,
    onRestore: (String) -> Unit,
    onDoubleTap: (String) -> Unit,
    onTap: (String) -> Unit,
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
                        onTap = { onTap(todo.id) },
                        onDoubleTap = { onDoubleTap(todo.id) },
                    )
                }
                .background(if (menuOpen) colors.box else colors.archiveBox, BubbleShape)
                .then(
                    if (todo.isImportant)
                        Modifier.border(1.5.dp, colors.theme, BubbleShape)
                    else Modifier
                )
                .padding(horizontal = BubblePaddingH, vertical = BubblePaddingV),
        ) {
            LinkedText(todo.todo, 15.sp, GmarketSans, if (isToday) colors.mainText else colors.doneText)
        }
    }
}
