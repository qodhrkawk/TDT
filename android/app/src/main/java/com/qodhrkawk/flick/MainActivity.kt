package com.qodhrkawk.flick

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
        val pagerState = rememberPagerState(pageCount = { 2 })

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
                    0 -> TodoScreen(
                        state = state,
                        onOpenSettings = { showSettings = true },
                        onOpenArchive = { scope.launch { pagerState.animateScrollToPage(1) } },
                    )
                    else -> ArchiveScreen(
                        state = state,
                        active = pagerState.currentPage == 1,
                        onBack = { scope.launch { pagerState.animateScrollToPage(0) } },
                    )
                }
            }

            if (showSettings) {
                Box(Modifier.fillMaxSize().background(colors.bg)) {
                    SettingsScreen(state, onBack = { showSettings = false })
                }
            }
        }

        BackHandler(enabled = showSettings || pagerState.currentPage == 1) {
            if (showSettings) {
                showSettings = false
            } else {
                scope.launch { pagerState.animateScrollToPage(0) }
            }
        }
    }
}
