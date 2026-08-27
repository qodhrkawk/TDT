package com.qodhrkawk.flick.ui

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qodhrkawk.flick.BuildConfig
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.GmarketSans
import com.qodhrkawk.flick.ui.theme.ThemeColors
import com.qodhrkawk.flick.ui.theme.ThemeNames

private const val INQUIRY_MAIL = "qodhrkawk@gmail.com"

@Composable
fun SettingsScreen(state: FlickAppState, onBack: () -> Unit) {
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
                "설정",
                fontSize = 18.sp,
                fontFamily = GmarketSans,
                fontWeight = FontWeight.Bold,
                color = colors.mainText,
            )
        }

        SectionTitle("화면 스타일")
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .background(colors.box, BubbleShape),
        ) {
            TraitRow("시스템 설정", SettingsStore.TRAIT_SYSTEM, state)
            TraitRow("라이트 모드", SettingsStore.TRAIT_LIGHT, state)
            TraitRow("다크 모드", SettingsStore.TRAIT_DARK, state)
        }

        SectionTitle("테마 색상")
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .background(colors.box, BubbleShape)
                .padding(vertical = 14.dp),
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                ThemeColors.forEachIndexed { index, color ->
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .then(
                                if (state.themeIndex == index)
                                    Modifier.border(2.dp, colors.mainText, CircleShape)
                                else Modifier
                            )
                            .padding(4.dp)
                            .background(color, CircleShape)
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null,
                            ) { state.setTheme(index) },
                    )
                }
            }
            Spacer(Modifier.height(10.dp))
            Text(
                ThemeNames[state.themeIndex],
                fontSize = 13.sp,
                fontFamily = GmarketSans,
                color = colors.subText,
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }

        SectionTitle("지원")
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .background(colors.box, BubbleShape),
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        if (!launchInquiryMail(context)) showMailFallback = true
                    }
                    .padding(horizontal = 16.dp, vertical = 15.dp),
            ) {
                Text(
                    "1:1 문의하기",
                    fontSize = 15.sp,
                    fontFamily = GmarketSans,
                    color = colors.mainText,
                )
            }
        }

        Spacer(Modifier.height(24.dp))
        Text(
            "Flick ${BuildConfig.VERSION_NAME}",
            fontSize = 12.sp,
            fontFamily = GmarketSans,
            color = colors.inactive,
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 30.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )
    }

    // 메일 앱이 없을 때 2단계 폴백: 주소 안내 + 복사
    if (showMailFallback) {
        AlertDialog(
            onDismissRequest = { showMailFallback = false },
            containerColor = colors.box,
            title = {
                Text("메일 앱을 찾을 수 없어요", fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
            },
            text = {
                Text(
                    "아래 주소로 문의를 보내주세요.\n$INQUIRY_MAIL",
                    fontSize = 14.sp,
                    fontFamily = GmarketSans,
                    color = colors.subText,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("Flick", INQUIRY_MAIL))
                    showMailFallback = false
                }) { Text("주소 복사", color = colors.theme, fontFamily = GmarketSans) }
            },
            dismissButton = {
                TextButton(onClick = { showMailFallback = false }) {
                    Text("닫기", color = colors.subText, fontFamily = GmarketSans)
                }
            },
        )
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        title,
        fontSize = 13.sp,
        fontFamily = GmarketSans,
        color = Flick.colors.subText,
        modifier = Modifier.padding(start = 20.dp, top = 22.dp, bottom = 8.dp),
    )
}

@Composable
private fun TraitRow(label: String, value: String, state: FlickAppState) {
    val colors = Flick.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { state.changeTrait(value) }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, fontSize = 15.sp, fontFamily = GmarketSans, color = colors.mainText)
        Spacer(Modifier.weight(1f))
        CheckCircle(
            checked = state.trait == value,
            color = colors.theme,
            inactive = colors.inactive,
            modifier = Modifier.size(20.dp),
        )
    }
}

/** 본문 하단에 앱/기기 정보 자동 첨부 (iOS와 동일 포맷) */
private fun launchInquiryMail(context: Context): Boolean {
    val body = "\n\n--------\nFlick v${BuildConfig.VERSION_NAME} / Android ${Build.VERSION.RELEASE} / ${Build.MODEL}"
    val intent = Intent(Intent.ACTION_SENDTO).apply {
        data = Uri.parse("mailto:")
        putExtra(Intent.EXTRA_EMAIL, arrayOf(INQUIRY_MAIL))
        putExtra(Intent.EXTRA_SUBJECT, "Flick 문의")
        putExtra(Intent.EXTRA_TEXT, body)
    }
    return try {
        context.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }
}
