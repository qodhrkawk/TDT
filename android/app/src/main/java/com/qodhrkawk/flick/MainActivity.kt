package com.qodhrkawk.flick

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.qodhrkawk.flick.data.SettingsStore
import com.qodhrkawk.flick.data.SharedPrefsKeyValueStore
import com.qodhrkawk.flick.data.TodoStore
import com.qodhrkawk.flick.ui.ArchiveScreen
import com.qodhrkawk.flick.ui.FlickAppState
import com.qodhrkawk.flick.ui.FlickToast
import com.qodhrkawk.flick.ui.SettingsScreen
import com.qodhrkawk.flick.ui.TodoScreen
import com.qodhrkawk.flick.ui.theme.Flick
import com.qodhrkawk.flick.ui.theme.FlickTheme
import com.qodhrkawk.flick.widget.WidgetUpdater
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { FlickRoot() }
    }
}

// iOS ControlPageViewController: [아카이브(0), 오늘 할 일(1)], 시작은 오늘 할 일
private const val PAGE_ARCHIVE = 0
private const val PAGE_MAIN = 1

@Composable
fun FlickRoot() {
    val context = LocalContext.current.applicationContext
    val state = remember {
        FlickAppState(
            store = TodoStore(SharedPrefsKeyValueStore(context)),
            settings = SettingsStore(context),
            onDataChanged = { WidgetUpdater.sync(context) },
        ).also { it.start() }
    }

    FlickTheme(state.themeIndex, state.trait) {
        val colors = Flick.colors
        val scope = rememberCoroutineScope()
        var showSettings by remember { mutableStateOf(false) }
        val pagerState = rememberPagerState(initialPage = PAGE_MAIN, pageCount = { 2 })

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(colors.bg)
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding(),
        ) {
            HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
                when (page) {
                    PAGE_ARCHIVE -> ArchiveScreen(
                        state = state,
                        active = pagerState.currentPage == PAGE_ARCHIVE,
                        onBack = { scope.launch { pagerState.animateScrollToPage(PAGE_MAIN) } },
                    )
                    else -> TodoScreen(
                        state = state,
                        active = pagerState.currentPage == PAGE_MAIN && !showSettings,
                        onOpenSettings = { showSettings = true },
                        onOpenArchive = { scope.launch { pagerState.animateScrollToPage(PAGE_ARCHIVE) } },
                    )
                }
            }

            // 설정: 아래에서 올라오는 풀스크린 모달 (iOS present modal)
            AnimatedVisibility(
                visible = showSettings,
                enter = slideInVertically(tween(300)) { it },
                exit = slideOutVertically(tween(300)) { it },
            ) {
                Box(Modifier.fillMaxSize().background(colors.bg)) {
                    SettingsScreen(state, onClose = { showSettings = false })
                }
            }

            FlickToast(state.toastMessage) { state.toastMessage = null }
        }

        BackHandler(enabled = showSettings || pagerState.currentPage == PAGE_ARCHIVE) {
            if (showSettings) {
                showSettings = false
            } else {
                scope.launch { pagerState.animateScrollToPage(PAGE_MAIN) }
            }
        }
    }
}
