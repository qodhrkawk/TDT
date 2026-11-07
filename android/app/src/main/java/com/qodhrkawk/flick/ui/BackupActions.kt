package com.qodhrkawk.flick.ui

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.qodhrkawk.flick.BuildConfig
import com.qodhrkawk.flick.data.BackupContent
import com.qodhrkawk.flick.data.BackupMergeResult
import com.qodhrkawk.flick.data.FlickBackup
import java.io.File
import java.time.Instant
import java.time.LocalDate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** 설정 화면의 데이터 내보내기/가져오기 흐름에서 띄우는 창 */
sealed interface BackupDialog {
    /** 공유 전 안내: 파일은 암호화되지 않는다 */
    data class ExportWarning(val content: BackupContent) : BackupDialog

    /** 합칠 결과 확인 */
    data class ImportConfirm(val result: BackupMergeResult) : BackupDialog

    /** 확인 버튼만 있는 안내 */
    data class Notice(val message: String) : BackupDialog
}

/** 가져오기에서 고를 수 있는 파일. 메신저로 받은 JSON은 형식이 octet-stream으로 붙기도 한다 */
val BackupMimeTypes = arrayOf("application/json", "application/octet-stream", "text/plain")

private const val SHARE_DIR = "backup"

/** 캐시 폴더에 백업 파일을 쓰고 공유 화면을 연다. 이전에 만든 공유 파일은 지운다 */
suspend fun shareBackup(context: Context, content: BackupContent) {
    val file = withContext(Dispatchers.IO) {
        val dir = File(context.cacheDir, SHARE_DIR).apply {
            deleteRecursively()
            mkdirs()
        }
        File(dir, FlickBackup.fileName(LocalDate.now())).apply {
            writeText(FlickBackup.exportJson(content, BuildConfig.VERSION_NAME, Instant.now()))
        }
    }
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "application/json"
        putExtra(Intent.EXTRA_STREAM, uri)
        clipData = ClipData.newRawUri(file.name, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(send, null))
}

/** 고른 파일을 끝까지 읽어 검증한다. 실패하면 BackupException 또는 입출력 예외 */
suspend fun readBackup(context: Context, uri: Uri): BackupContent = withContext(Dispatchers.IO) {
    val text = context.contentResolver.openInputStream(uri)?.use { it.readBytes().decodeToString() }
        ?: throw java.io.IOException("파일을 열 수 없음")
    FlickBackup.parse(text)
}
