package com.qodhrkawk.flick.ui

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
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
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import com.qodhrkawk.flick.ui.theme.ThemeColors
import com.qodhrkawk.flick.ui.theme.ThemeNames

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
