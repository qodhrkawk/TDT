package com.qodhrkawk.flick.ui

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.BuildConfig
import com.qodhrkawk.flick.R
import com.qodhrkawk.flick.data.BackupException
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import com.qodhrkawk.flick.ui.theme.ThemeColors
import com.qodhrkawk.flick.ui.theme.ThemeNames
import kotlinx.coroutines.launch

/** img_check는 여백 포함 40 — iOS와 같은 크기로 보이는 값 */
private val SelectedCheckSize = 40.dp

private const val INQUIRY_MAIL = "qodhrkawk@gmail.com"
private const val INQUIRY_SUBJECT = "Flick 1:1 문의하기"

/** iOS SettingViewController: imgSettings 타이틀 + 닫기 버튼, 섹션 헤더(제목+부제) 3개 */
@Composable
fun SettingsScreen(state: FlickAppState, onClose: () -> Unit) {
    val colors = Flick.colors
    val context = LocalContext.current
    var showMailFallback by remember { mutableStateOf(false) }
    var backupDialog by remember { mutableStateOf<BackupDialog?>(null) }
    val scope = rememberCoroutineScope()

    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            val incoming = try {
                readBackup(context, uri)
            } catch (e: BackupException.NewerVersion) {
                backupDialog = BackupDialog.Notice("앱을 업데이트한 뒤 다시 가져와 주세요")
                return@launch
            } catch (e: Exception) {
                backupDialog = BackupDialog.Notice("Flick 데이터 파일이 아니에요")
                return@launch
            }
            val result = state.previewImport(incoming)
            if (result.added == 0) {
                state.showToast("이미 모두 들어 있어요")
            } else {
                backupDialog = BackupDialog.ImportConfirm(result)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.bg)
            .verticalScroll(rememberScrollState()),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                painterResource(R.drawable.img_settings),
                contentDescription = "설정",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier.height(25.dp),
            )
            Spacer(Modifier.weight(1f))
            Image(
                painterResource(R.drawable.btn_close_settings),
                contentDescription = "닫기",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier
                    .size(24.dp)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { onClose() },
            )
        }

        SectionHeader("화면 스타일", "어떤 모드를 따를지 설정합니다.")
        TraitRow("시스템 설정", SettingsStore.TRAIT_SYSTEM, R.drawable.img_theme_os, state)
        RowSeparator()
        TraitRow("라이트 모드", SettingsStore.TRAIT_LIGHT, R.drawable.img_theme_light, state)
        RowSeparator()
        TraitRow("다크 모드", SettingsStore.TRAIT_DARK, R.drawable.img_theme_dark, state)

        SectionHeader("테마", "하이라이트 색상이 변경됩니다.")
        ThemeNames.forEachIndexed { index, name ->
            ThemeRow(index, name, state)
            if (index < ThemeNames.lastIndex) RowSeparator()
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    if (!launchInquiryMail(context)) showMailFallback = true
                },
        ) {
            SectionHeader("1:1 문의하기", "누르면 메일 앱으로 이동합니다.")
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    val content = state.exportContent()
                    if (content.isEmpty) {
                        state.showToast("내보낼 항목이 없어요")
                    } else {
                        backupDialog = BackupDialog.ExportWarning(content)
                    }
                },
        ) {
            SectionHeader("데이터 내보내기", "할 일과 아카이브를 파일로 저장합니다.")
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { importLauncher.launch(BackupMimeTypes) },
        ) {
            SectionHeader("데이터 가져오기", "파일의 할 일을 지금 데이터에 합칩니다.")
        }

        Spacer(Modifier.height(30.dp))
        Text(
            "Flick ${BuildConfig.VERSION_NAME}",
            fontSize = 12.sp,
            fontFamily = GmarketSans,
            color = colors.inactive,
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 40.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )
    }

    when (val dialog = backupDialog) {
        is BackupDialog.ExportWarning -> FlickDialogOverlay(
            message = "파일은 암호화되지 않아요",
            detail = "공유할 곳을 확인한 뒤 보내주세요.",
            confirmLabel = "계속",
            onCancel = { backupDialog = null },
            onConfirm = {
                backupDialog = null
                scope.launch {
                    runCatching { shareBackup(context, dialog.content) }
                        .onFailure { state.showToast("내보내지 못했어요") }
                }
            },
        )
        is BackupDialog.ImportConfirm -> FlickDialogOverlay(
            message = "새 항목 ${dialog.result.added}개를 추가할게요.\n이미 있는 ${dialog.result.skipped}개는 건너뛰어요.",
            confirmLabel = "가져오기",
            onCancel = { backupDialog = null },
            onConfirm = {
                backupDialog = null
                state.applyImport(dialog.result)
                state.showToast("${dialog.result.added}개를 추가했어요")
            },
        )
        is BackupDialog.Notice -> FlickDialogOverlay(
            message = dialog.message,
            confirmLabel = "확인",
            onConfirm = { backupDialog = null },
        )
        null -> Unit
    }

    if (showMailFallback) {
        MailFallbackSheet(
            onCopy = {
                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("Flick", INQUIRY_MAIL))
                showMailFallback = false
                state.showToast("이메일 주소를 복사했어요")
            },
            onClose = { showMailFallback = false },
        )
    }
}

@Composable
private fun SectionHeader(title: String, subtitle: String) {
    val colors = Flick.colors
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(68.dp)
            .padding(horizontal = 20.dp),
        verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center,
    ) {
        Text(title, fontSize = 16.sp, fontFamily = GmarketSans, color = colors.mainText)
        Spacer(Modifier.height(4.dp))
        Text(subtitle, fontSize = 12.sp, fontFamily = GmarketSans, color = colors.subText)
    }
}

@Composable
private fun RowSeparator() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .height(1.dp)
            .background(Flick.colors.inactiveSecondary.copy(alpha = 0.4f)),
    )
}

/** 화면 스타일 행 (h=98): 미리보기 이미지 + 라벨 + 선택 체크 */
@Composable
private fun TraitRow(label: String, value: String, imageRes: Int, state: FlickAppState) {
    val colors = Flick.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(98.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { state.changeTrait(value) }
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painterResource(imageRes),
            contentDescription = label,
            modifier = Modifier.height(74.dp),
        )
        Spacer(Modifier.width(16.dp))
        Text(label, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
        Spacer(Modifier.weight(1f))
        if (state.trait == value) {
            Image(
                painterResource(R.drawable.img_check),
                contentDescription = "선택됨",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier.size(SelectedCheckSize),
            )
        }
    }
}

/** 테마 행 (h=48): 색 원 + 이름 + 선택 체크 */
@Composable
private fun ThemeRow(index: Int, name: String, state: FlickAppState) {
    val colors = Flick.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { state.setTheme(index) }
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(18.dp)
                .background(ThemeColors[index], CircleShape),
        )
        Spacer(Modifier.width(14.dp))
        Text(name, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
        Spacer(Modifier.weight(1f))
        if (state.themeIndex == index) {
            Image(
                painterResource(R.drawable.img_check),
                contentDescription = "선택됨",
                colorFilter = ColorFilter.tint(colors.mainText),
                modifier = Modifier.size(SelectedCheckSize),
            )
        }
    }
}

@Composable
private fun MailFallbackSheet(onCopy: () -> Unit, onClose: () -> Unit) {
    val colors = Flick.colors
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.6f))) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(20.dp)
                .background(colors.box, BubbleShape)
                .padding(20.dp),
        ) {
            Text(
                "메일 앱을 열 수 없어요",
                fontSize = 16.sp,
                fontFamily = GmarketSans,
                color = colors.mainText,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "아래 주소로 문의를 보내주세요.\n$INQUIRY_MAIL",
                fontSize = 14.sp,
                fontFamily = GmarketSans,
                color = colors.subText,
            )
            Spacer(Modifier.height(16.dp))
            Row {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .background(colors.typingText.copy(alpha = 0.08f), BubbleShape)
                        .clickable { onClose() },
                    contentAlignment = Alignment.Center,
                ) { Text("닫기", fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText) }
                Spacer(Modifier.width(10.dp))
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .background(colors.theme, BubbleShape)
                        .clickable { onCopy() },
                    contentAlignment = Alignment.Center,
                ) { Text("주소 복사", fontSize = 15.sp, fontFamily = GmarketSans, color = Color.White) }
            }
        }
    }
}

/** 본문 하단에 앱/기기 정보 자동 첨부 (iOS와 동일 포맷) */
private fun launchInquiryMail(context: Context): Boolean {
    val body = "\n\n\n--------\nFlick v${BuildConfig.VERSION_NAME} / Android ${Build.VERSION.RELEASE} / ${Build.MODEL}"
    val intent = Intent(Intent.ACTION_SENDTO).apply {
        data = Uri.parse("mailto:")
        putExtra(Intent.EXTRA_EMAIL, arrayOf(INQUIRY_MAIL))
        putExtra(Intent.EXTRA_SUBJECT, INQUIRY_SUBJECT)
        putExtra(Intent.EXTRA_TEXT, body)
    }
    return try {
        context.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }
}
