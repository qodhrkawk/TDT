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
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.data.firstContainedUrl
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

const val LinkOpenFailedMessage = "링크를 열 수 없어요"

private val DialogWidth = 301.dp

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
    onLinkOpenFailed: () -> Unit,
) {
    val colors = Flick.colors
    val uriHandler = LocalUriHandler.current
    var mode by remember(target?.id) { mutableStateOf(MenuMode.MENU) }
    var editText by remember(target?.id) {
        val text = target?.text.orEmpty()
        mutableStateOf(TextFieldValue(text, TextRange(text.length)))
    }
    val focusRequester = remember { FocusRequester() }

    if (target == null) return

    LaunchedEffect(mode) {
        if (mode == MenuMode.EDIT) focusRequester.requestFocus()
    }

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

        when (mode) {
            MenuMode.MENU -> {
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 16.dp),
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(colors.box, BubbleShape),
                    ) {
                        // 링크가 있으면 맨 위 (여러 개면 첫 링크 — iOS와 동일)
                        val linkUrl = remember(target.text) { target.text.firstContainedUrl }
                        if (linkUrl != null) {
                            MenuRow("링크 열기", colors.mainText) {
                                onDismiss()
                                runCatching { uriHandler.openUri(linkUrl) }
                                    .onFailure { onLinkOpenFailed() }
                            }
                            MenuSeparator()
                        }
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
                        // 아카이브에서는 수정할 수 없다 (iOS AlertViewController fromArchive)
                        if (!target.fromArchive) {
                            MenuRow("수정", colors.mainText) { mode = MenuMode.EDIT }
                            MenuSeparator()
                        }
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
            }

            MenuMode.DELETE_CONFIRM -> {
                ConfirmDialog(
                    message = "메모를 삭제할까요?",
                    onCancel = onDismiss,
                    onConfirm = { onDismiss(); onDelete(target.id) },
                    modifier = Modifier.align(Alignment.Center),
                )
            }

            MenuMode.EDIT -> {
                // iOS: 키보드 위 75 지점에 뜨는 높이 228 모달
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 75.dp)
                        .width(DialogWidth)
                        .background(colors.box, BubbleShape)
                        .padding(start = 16.dp, end = 16.dp, top = 20.dp, bottom = 16.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(128.dp)
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
                            modifier = Modifier
                                .fillMaxSize()
                                .focusRequester(focusRequester),
                        )
                    }
                    Spacer(Modifier.height(16.dp))
                    DialogButtons(
                        confirmLabel = "수정",
                        onCancel = onDismiss,
                        onConfirm = {
                            onDismiss()
                            if (editText.text.isNotBlank()) onEdit(target.id, editText.text)
                        },
                    )
                }
            }
        }
    }
}

/** 딤 배경 위 화면 중앙 확인 창. 떠 있는 동안 뒤쪽 화면을 누를 수 없다 */
@Composable
fun FlickDialogOverlay(
    message: String,
    onConfirm: () -> Unit,
    onCancel: (() -> Unit)? = null,
    detail: String? = null,
    confirmLabel: String = "삭제",
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {},
        contentAlignment = Alignment.Center,
    ) {
        ConfirmDialog(
            message = message,
            detail = detail,
            confirmLabel = confirmLabel,
            onCancel = onCancel,
            onConfirm = onConfirm,
        )
    }
}

/** iOS deleteCheckView: 폭 301, 문구 영역 + 취소/확인 버튼. onCancel이 없으면 확인 버튼만 */
@Composable
fun ConfirmDialog(
    message: String,
    onCancel: (() -> Unit)?,
    onConfirm: () -> Unit,
    modifier: Modifier = Modifier,
    detail: String? = null,
    confirmLabel: String = "삭제",
) {
    val colors = Flick.colors
    Column(
        modifier = modifier
            .width(DialogWidth)
            .background(colors.box, BubbleShape)
            .padding(start = 16.dp, end = 16.dp, bottom = 16.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 95.dp)
                .padding(vertical = 16.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    message,
                    fontSize = 16.sp,
                    fontFamily = GmarketSans,
                    color = colors.mainText,
                    textAlign = TextAlign.Center,
                )
                if (detail != null) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        detail,
                        fontSize = 14.sp,
                        fontFamily = GmarketSans,
                        color = colors.subText,
                        textAlign = TextAlign.Center,
                    )
                }
            }
        }
        DialogButtons(confirmLabel = confirmLabel, onCancel = onCancel, onConfirm = onConfirm)
    }
}

@Composable
private fun DialogButtons(confirmLabel: String, onCancel: (() -> Unit)?, onConfirm: () -> Unit) {
    val colors = Flick.colors
    Row {
        if (onCancel != null) {
            ConfirmButton(
                "취소",
                textColor = colors.mainText,
                bg = colors.typingText.copy(alpha = 0.08f),
                modifier = Modifier.weight(1f),
                onClick = onCancel,
            )
            Spacer(Modifier.width(8.dp))
        }
        ConfirmButton(
            confirmLabel,
            textColor = Color.White,
            bg = colors.theme,
            modifier = Modifier.weight(1f),
            onClick = onConfirm,
        )
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
