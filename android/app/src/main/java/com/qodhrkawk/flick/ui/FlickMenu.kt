package com.qodhrkawk.flick.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import kotlinx.coroutines.delay

/** 메뉴 대상 (iOS AlertViewController의 구성 플래그) */
data class MenuTarget(
    val id: String,
    val text: String,
    val showPin: Boolean = false,
    val isPinned: Boolean = false,
    val showSelect: Boolean = false,
    val fromArchive: Boolean = false,
)

private enum class MenuMode { MENU, DELETE_CONFIRM, EDIT }

/**
 * iOS AlertViewController 이식: 하단에서 올라오는 버튼 스택 + 취소.
 * 삭제 → 확인 뷰로 교체, 수정 → 텍스트 편집 뷰.
 */
@Composable
fun FlickActionMenu(
    target: MenuTarget?,
    onDismiss: () -> Unit,
    onPinToggle: (String) -> Unit,
    onSelect: (String) -> Unit,
    onEdit: (String, String) -> Unit,
    onDelete: (String) -> Unit,
) {
    val colors = Flick.colors
    var mode by remember(target?.id) { mutableStateOf(MenuMode.MENU) }
    var editText by remember(target?.id) { mutableStateOf(target?.text ?: "") }

    if (target == null) return

    Box(modifier = Modifier.fillMaxSize()) {
        // 딤 배경 — 바깥 탭으로 닫기 (편집 중에는 유지)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.6f))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { if (mode != MenuMode.EDIT) onDismiss() },
        )

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .imePadding()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp, vertical = 16.dp),
        ) {
            when (mode) {
                MenuMode.MENU -> {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.box, BubbleShape),
                    ) {
                        if (target.showPin && !target.fromArchive) {
                            MenuRow(if (target.isPinned) "고정 해제" else "고정", colors.mainText) {
                                onDismiss(); onPinToggle(target.id)
                            }
                            MenuSeparator()
                        }
                        if (target.showSelect && !target.fromArchive) {
                            MenuRow("선택", colors.mainText) {
                                onDismiss(); onSelect(target.id)
                            }
                            MenuSeparator()
                        }
                        MenuRow("수정", colors.mainText) { mode = MenuMode.EDIT }
                        MenuSeparator()
                        MenuRow("삭제", colors.theme) { mode = MenuMode.DELETE_CONFIRM }
                    }
                    Spacer(Modifier.height(10.dp))
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.box, BubbleShape),
                    ) {
                        MenuRow("취소", colors.mainText) { onDismiss() }
                    }
                }

                MenuMode.DELETE_CONFIRM -> {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.box, BubbleShape)
                            .padding(20.dp),
                    ) {
                        Text(
                            "메모를 삭제할까요?",
                            fontSize = 16.sp,
                            fontFamily = GmarketSans,
                            color = colors.mainText,
                            modifier = Modifier.padding(vertical = 16.dp),
                        )
                        Row {
                            ConfirmButton(
                                "취소",
                                textColor = colors.mainText,
                                bg = colors.typingText.copy(alpha = 0.08f),
                                modifier = Modifier.weight(1f),
                            ) { onDismiss() }
                            Spacer(Modifier.width(10.dp))
                            ConfirmButton(
                                "삭제",
                                textColor = Color.White,
                                bg = colors.theme,
                                modifier = Modifier.weight(1f),
                            ) { onDismiss(); onDelete(target.id) }
                        }
                    }
                }

                MenuMode.EDIT -> {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.box, BubbleShape)
                            .padding(16.dp),
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(colors.box, BubbleShape)
                                .border(1.dp, colors.typingText.copy(alpha = 0.08f), BubbleShape)
                                .padding(horizontal = 18.dp, vertical = 13.dp),
                        ) {
                            BasicTextField(
                                value = editText,
                                onValueChange = { editText = it },
                                textStyle = TextStyle(
                                    fontSize = 15.sp,
                                    fontFamily = GmarketSans,
                                    color = colors.mainText,
                                ),
                                cursorBrush = SolidColor(colors.theme),
                                modifier = Modifier.fillMaxWidth(),
                            )
                        }
                        Spacer(Modifier.height(12.dp))
                        Row {
                            ConfirmButton(
                                "취소",
                                textColor = colors.mainText,
                                bg = colors.typingText.copy(alpha = 0.08f),
                                modifier = Modifier.weight(1f),
                            ) { onDismiss() }
                            Spacer(Modifier.width(10.dp))
                            ConfirmButton(
                                "수정",
                                textColor = Color.White,
                                bg = colors.theme,
                                modifier = Modifier.weight(1f),
                            ) {
                                onDismiss()
                                if (editText.isNotBlank()) onEdit(target.id, editText)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MenuRow(label: String, color: Color, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(60.dp)
            .clickable { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Text(label, fontSize = 16.sp, fontFamily = GmarketSans, color = color)
    }
}

@Composable
private fun MenuSeparator() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Flick.colors.inactiveSecondary),
    )
}

@Composable
private fun ConfirmButton(
    label: String,
    textColor: Color,
    bg: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier
            .height(48.dp)
            .background(bg, BubbleShape)
            .clickable { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Text(label, fontSize = 15.sp, fontFamily = GmarketSans, color = textColor)
    }
}

/** iOS CustomToastView: imgToast 배경 + Gmarket 14 boxColor 텍스트 */
@Composable
fun FlickToast(message: String?, onDone: () -> Unit) {
    AnimatedVisibility(
        visible = message != null,
        enter = fadeIn(tween(150)) + slideInVertically(tween(150)) { it / 2 },
        exit = fadeOut(tween(200)) + slideOutVertically(tween(200)) { it / 2 },
        modifier = Modifier.fillMaxSize(),
    ) {
        val text = message ?: ""
        Box(modifier = Modifier.fillMaxSize().padding(bottom = 120.dp)) {
            Box(
                modifier = Modifier.align(Alignment.BottomCenter),
                contentAlignment = Alignment.Center,
            ) {
                Image(painterResource(R.drawable.img_toast), contentDescription = null)
                Text(
                    text,
                    fontSize = 14.sp,
                    fontFamily = GmarketSans,
                    color = Flick.colors.box,
                )
            }
        }
    }
    LaunchedEffect(message) {
        if (message != null) {
            delay(1800)
            onDone()
        }
    }
}
