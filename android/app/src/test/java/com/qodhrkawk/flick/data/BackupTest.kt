package com.qodhrkawk.flick.data

import java.time.Instant
import java.time.LocalDate
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * iOS `TodoStoreTests.swift` 16~19번(백업 파일·정리·합치기·스토어 연결)을 그대로 이식.
 * 샘플 파일 `flick-backup-v1.json`은 iOS `TDT/Tests/fixtures`와 같은 파일이다.
 */
class BackupTest {

    private fun bi(text: String, date: String, important: Boolean = false) = BackupItem(date, text, important)
    private fun bs(date: String, items: List<BackupItem>) = BackupSection(date, items)
    private fun content(
        todos: List<BackupSection> = emptyList(),
        pinned: List<BackupItem> = emptyList(),
        archive: List<BackupSection> = emptyList(),
    ) = BackupContent(todos, pinned, archive)

    private val empty = content()
    private val d = "2026.11.07"
    private val guides = BackupMerger.guideTexts.map { bi(it, d) }
    private val g1 = BackupMerger.guideTexts[0]
    private val g2 = BackupMerger.guideTexts[1]
    private val g3 = BackupMerger.guideTexts[2]

    private fun fixture(): String =
        javaClass.classLoader!!.getResource("flick-backup-v1.json")!!.readText()

    private fun parseError(json: String): BackupException? =
        try {
            FlickBackup.parse(json)
            null
        } catch (e: BackupException) {
            e
        }

    private val dirty = content(
        todos = listOf(
            bs("2021.01.25 10:30", listOf(bi("옛 날짜", "2021.01.25 10:30"), bi(" \n", "2021.01.25 10:30"))),
            bs("2021.01.25", listOf(bi("같은 날", "2021.01.25"))),
            bs("", listOf(bi("섹션 날짜 없음", "2021.02.01"))),
            bs("", listOf(bi("날짜 모두 없음", ""))),
            bs("2021.03.01", listOf(bi("", "2021.03.01"))),
        ),
        pinned = listOf(bi("고정", "2021.01.25 10:30"), bi("   ", "2021.01.25")),
        archive = listOf(
            bs("2021.01.26", listOf(bi("작년 완료", "2021.01.25 10:30"))),
            bs("2021.02.26", listOf(bi("최근 완료", "2021.02.25"))),
        ),
    )

    @Test
    fun `isValidDate - 정상, 끝 줄바꿈과 아라비아 숫자 거절`() {
        assertTrue(FlickBackup.isValidDate("2026.11.07"))
        assertFalse(FlickBackup.isValidDate("2026.11.07\n"))
        assertFalse(FlickBackup.isValidDate("٢٠٢٦.١١.٠٧"))
    }

    // 17. 내보내기 정리

    @Test
    fun `17 sanitize - 날짜 정리, 합치기, 정렬, 공백 메모 제외`() {
        val clean = FlickBackup.sanitized(dirty, today = d)
        assertEquals(listOf("2021.01.25", "2021.02.01", d), clean.todos.map { it.date })
        assertEquals(listOf("옛 날짜", "같은 날"), clean.todos[0].items.map { it.todo })
        assertEquals(d, clean.todos[2].items[0].date)
        assertEquals(listOf("2021.01.25"), clean.pinned.map { it.date })
        assertEquals(listOf("2021.02.26", "2021.01.26"), clean.archive.map { it.date })
        assertEquals("2021.01.25", clean.archive[1].items[0].date)
        assertTrue(FlickBackup.sanitized(content(todos = listOf(bs("2021.03.01", listOf(bi("", "2021.03.01"))))), d).isEmpty)
    }

    // 16. 백업 파일

    @Test
    fun `16 backup - iOS 샘플 파일 읽기`() {
        val parsed = FlickBackup.parse(fixture())
        assertEquals(listOf("2026.11.06", "2026.11.07"), parsed.todos.map { it.date })
        assertEquals(2, parsed.todos[0].items.size)
        assertEquals("첫 줄\n둘째 줄 \"인용\" \\ 끝", parsed.todos[1].items[0].todo)
        assertTrue(parsed.todos[1].items[0].isImportant)
        assertEquals(listOf("고정 메모"), parsed.pinned.map { it.todo })
        assertEquals("2026.11.06", parsed.archive[0].date)
        assertEquals("2026.11.02", parsed.archive[0].items[0].date)
    }

    @Test
    fun `16 backup - 내보내고 다시 읽으면 같고 헤더 값이 맞다`() {
        val parsed = FlickBackup.parse(fixture())
        val first = parsed.todos[0]
        val emoji = parsed.copy(
            todos = listOf(first.copy(items = listOf(first.items[0].copy(todo = "이모지 \uD83D\uDE00 포함")) + first.items.drop(1))) +
                parsed.todos.drop(1),
        )
        val exported = FlickBackup.exportJson(emoji, appVersion = "1.0.0", now = Instant.ofEpochSecond(1_794_000_000))
        assertEquals(emoji, FlickBackup.parse(exported))

        val header = Json.parseToJsonElement(exported).jsonObject
        assertEquals("flick-backup", header["format"]!!.jsonPrimitive.content)
        assertEquals(1, header["version"]!!.jsonPrimitive.int)
        assertEquals("android", header["source"]!!.jsonObject["platform"]!!.jsonPrimitive.content)
        assertEquals("2026-11-06T21:20:00Z", header["exportedAt"]!!.jsonPrimitive.content)
    }

    @Test
    fun `16 backup - 잘못된 파일 거절`() {
        val goodTail = "\"exportedAt\":\"x\",\"source\":{\"platform\":\"ios\",\"appVersion\":\"3.1.0\"}"
        fun file(todos: String) =
            "{\"format\":\"flick-backup\",\"version\":1,$goodTail,\"todos\":$todos,\"pinned\":[],\"archive\":[]}"

        assertTrue(parseError("not json") is BackupException.InvalidFile)
        assertTrue(parseError("{\"format\":\"other\",\"version\":1}") is BackupException.InvalidFile)
        assertTrue(parseError("{\"format\":\"flick-backup\",\"version\":2}") is BackupException.NewerVersion)
        assertTrue(parseError(file("[{\"date\":\"2026-11-07\",\"items\":[]}]")) is BackupException.InvalidFile)
        assertTrue(
            parseError(file("[{\"date\":\"2026.11.07\",\"items\":[{\"date\":\"2026.11.07\",\"todo\":\" \\n\",\"isImportant\":false}]}]"))
                is BackupException.InvalidFile
        )
        // 안드로이드 추가: 타입이 틀린 값과 빠진 필드
        assertTrue(parseError("{\"format\":\"flick-backup\",\"version\":\"1\"}") is BackupException.InvalidFile)
        assertTrue(
            parseError(file("[{\"date\":\"2026.11.07\",\"items\":[{\"date\":\"2026.11.07\",\"todo\":\"a\",\"isImportant\":\"true\"}]}]"))
                is BackupException.InvalidFile
        )
        assertTrue(
            parseError("{\"format\":\"flick-backup\",\"version\":1,$goodTail,\"todos\":[],\"pinned\":[]}") is BackupException.InvalidFile
        )
        assertTrue(
            parseError(file("[{\"date\":\"2026.11.07\",\"items\":[{\"date\":\"2026.11.07\",\"todo\":7,\"isImportant\":false}]}]"))
                is BackupException.InvalidFile
        )
    }

    @Test
    fun `16 backup - 파일 이름`() {
        assertEquals("flick-backup-2026-11-07.json", FlickBackup.fileName(LocalDate.of(2026, 11, 7)))
    }

    // 18. 합치기

    @Test
    fun `18 merge - 추가와 건너뜀, 날짜 오름차순 삽입, 기존 뒤에 추가`() {
        val m = BackupMerger.merge(
            current = content(todos = listOf(bs("2026.11.05", listOf(bi("a", "2026.11.05"))), bs(d, listOf(bi("b", d))))),
            incoming = content(todos = listOf(bs("2026.11.06", listOf(bi("c", "2026.11.06"))), bs(d, listOf(bi("b", d), bi("d", d))))),
            today = d,
        )
        assertEquals(2, m.added)
        assertEquals(1, m.skipped)
        assertEquals(listOf("2026.11.05", "2026.11.06", d), m.merged.todos.map { it.date })
        assertEquals(listOf("b", "d"), m.merged.todos[2].items.map { it.todo })
    }

    @Test
    fun `18 merge - a-b개만 추가하고 다시 가져와도 늘지 않음`() {
        val file = content(todos = listOf(bs(d, listOf(bi("운동", d), bi("운동", d)))))
        val m = BackupMerger.merge(content(todos = listOf(bs(d, listOf(bi("운동", d))))), file, d)
        assertEquals(1, m.added)
        assertEquals(1, m.skipped)
        val again = BackupMerger.merge(m.merged, file, d)
        assertEquals(0, again.added)
        assertEquals(2, again.skipped)
    }

    @Test
    fun `18 merge - 일반과 고정은 한 묶음, 새 고정은 뒤에, 기존 상태 유지`() {
        val m = BackupMerger.merge(
            current = content(todos = listOf(bs(d, listOf(bi("x", d)))), pinned = listOf(bi("p", "2026.11.01"))),
            incoming = content(
                todos = listOf(bs("2026.11.01", listOf(bi("p", "2026.11.01")))),
                pinned = listOf(bi("x", d), bi("q", d, important = true), bi("r", d)),
            ),
            today = d,
        )
        assertEquals(2, m.added)
        assertEquals(2, m.skipped)
        assertEquals(listOf("p", "q", "r"), m.merged.pinned.map { it.todo })
        assertFalse(m.merged.todos[0].items[0].isImportant)
    }

    @Test
    fun `18 merge - 아카이브 내림차순 삽입, 완료와 작성 날짜로 비교, 일반과 따로`() {
        val m = BackupMerger.merge(
            current = content(todos = listOf(bs(d, listOf(bi("t", d)))), archive = listOf(bs("2026.11.05", listOf(bi("old", "2026.11.01"))))),
            incoming = content(
                archive = listOf(
                    bs("2026.11.06", listOf(bi("t", d))),
                    bs("2026.11.05", listOf(bi("old", "2026.11.01"), bi("old", "2026.10.01"))),
                    bs("2026.11.04", listOf(bi("older", "2026.11.01"))),
                ),
            ),
            today = d,
        )
        assertEquals(listOf("2026.11.06", "2026.11.05", "2026.11.04"), m.merged.archive.map { it.date })
        assertEquals(listOf("2026.11.01", "2026.10.01"), m.merged.archive[1].items.map { it.date })
        assertEquals(3, m.added)
        assertEquals(1, m.skipped)
    }

    @Test
    fun `18 merge - 기기 안내 세트 제거와 변화 없음 조건`() {
        var m = BackupMerger.merge(
            content(todos = listOf(bs(d, guides))),
            content(todos = listOf(bs("2026.11.01", listOf(bi("진짜", "2026.11.01"))))),
            d,
        )
        assertEquals(listOf("2026.11.01"), m.merged.todos.map { it.date })
        assertEquals(1, m.added)

        val onlyGuides = content(todos = listOf(bs("2026.11.01", BackupMerger.guideTexts.map { bi(it, "2026.11.01") })))
        m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), onlyGuides, d)
        assertEquals(0, m.added)
        assertEquals(0, m.skipped)
        assertEquals(listOf(d), m.merged.todos.map { it.date })

        m = BackupMerger.merge(
            content(todos = listOf(bs(d, guides.take(2)))),
            content(todos = listOf(bs("2026.11.01", listOf(bi("진짜", "2026.11.01"))))),
            d,
        )
        assertEquals(2, m.merged.todos.size)

        val withGuide = content(todos = listOf(bs("2026.11.01", BackupMerger.guideTexts.map { bi(it, "2026.11.01") } + bi("진짜", "2026.11.01"))))
        m = BackupMerger.merge(empty, withGuide, d)
        assertEquals(listOf("진짜"), m.merged.todos[0].items.map { it.todo })
        assertEquals(1, m.added)
    }

    @Test
    fun `18 merge - 옛 날짜가 남은 기기에서 자기 파일 재가져오기`() {
        val legacy = content(todos = listOf(bs("2021.01.25 10:30", listOf(bi("옛 메모", "2021.01.25 10:30")))))
        var m = BackupMerger.merge(legacy, FlickBackup.sanitized(legacy, d), d)
        assertEquals(0, m.added)
        assertEquals(1, m.skipped)

        m = BackupMerger.merge(dirty, FlickBackup.sanitized(dirty, d), d)
        assertEquals(0, m.added)
        assertEquals(dirty, m.merged)

        val odd = content(
            todos = listOf(bs("2021.03.01", listOf(bi("빈 날짜", ""), bi("슬래시", "2021/03/02")))),
            pinned = listOf(bi("고정 빈 날짜", "")),
            archive = listOf(bs("2021.04.01", listOf(bi("완료 빈 날짜", ""))), bs("x", listOf(bi("섹션 날짜 불가", "2021.01.01")))),
        )
        m = BackupMerger.merge(odd, FlickBackup.sanitized(odd, d), d)
        assertEquals(0, m.added)
        assertEquals(5, m.skipped)
        assertEquals(odd, m.merged)
    }

    @Test
    fun `18 merge - 대량 데이터 성능과 정렬`() {
        // iOS는 1초 기준. JVM 첫 실행(JIT 전) 편차를 감안해 2초로 둔다
        val bigItems = (0 until 5000).map { bi("메모 $it", d) }
        var started = System.nanoTime()
        var m = BackupMerger.merge(content(todos = listOf(bs(d, bigItems))), content(todos = listOf(bs(d, bigItems))), d)
        assertEquals(0, m.added)
        assertTrue(System.nanoTime() - started < 2_000_000_000)

        val manyDates = (0 until 5000).map { i ->
            "%04d.%02d.%02d".format(2000 + i / 336, i / 28 % 12 + 1, i % 28 + 1)
        }
        val manyTodos = manyDates.reversed().map { bs(it, listOf(bi("메모 $it", it))) }
        started = System.nanoTime()
        m = BackupMerger.merge(empty, content(todos = manyTodos), d)
        assertEquals(5000, m.added)
        assertTrue(System.nanoTime() - started < 2_000_000_000)
        assertEquals(manyDates.sorted(), m.merged.todos.map { it.date })

        started = System.nanoTime()
        m = BackupMerger.merge(empty, content(archive = manyTodos), d)
        assertEquals(5000, m.added)
        assertTrue(System.nanoTime() - started < 2_000_000_000)
        assertEquals(manyDates.sortedDescending(), m.merged.archive.map { it.date })
    }

    @Test
    fun `18 merge - 안내 세트 판정`() {
        val real = bi("진짜", "2026.11.01")
        var m = BackupMerger.merge(
            content(todos = listOf(bs(d, listOf(bi(g1, d), bi(g2, d, important = true), bi(g3, d))))),
            content(todos = listOf(bs("2026.11.01", listOf(real)))),
            d,
        )
        assertEquals(2, m.merged.todos.size)
        assertEquals(3, m.merged.todos[1].items.size)

        val importantFile = content(todos = listOf(bs("2026.11.01", listOf(bi(g1, "2026.11.01"), bi(g2, "2026.11.01", important = true), bi(g3, "2026.11.01")))))
        m = BackupMerger.merge(empty, importantFile, d)
        assertEquals(3, m.added)

        m = BackupMerger.merge(
            content(todos = listOf(bs(d, listOf(bi(g1, d), bi(g2, d), bi(g3, "2026.11.01"))))),
            content(todos = listOf(bs("2026.11.01", listOf(real)))),
            d,
        )
        assertEquals(2, m.merged.todos.size)

        m = BackupMerger.merge(content(todos = listOf(bs(d, listOf(bi(g1, d))))), content(todos = listOf(bs(d, listOf(bi(g2, d), bi(g3, d))))), d)
        assertEquals(2, m.added)
        assertEquals(listOf(g1, g2, g3), m.merged.todos[0].items.map { it.todo })
    }

    @Test
    fun `18 merge - 안내 세트 두 벌과 섞인 경우`() {
        val real = bi("진짜", "2026.11.01")
        val doubleSet = content(
            todos = listOf(bs("2026.11.01", BackupMerger.guideTexts.map { bi(it, "2026.11.01") } + BackupMerger.guideTexts.map { bi(it, "2026.11.01") })),
        )
        var m = BackupMerger.merge(empty, doubleSet, d)
        assertEquals(0, m.added)
        assertEquals(0, m.skipped)
        assertTrue(m.merged.isEmpty)

        m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), doubleSet, d)
        assertEquals(0, m.added)
        assertEquals(listOf(bs(d, guides)), m.merged.todos)

        val doubleSetReal = content(todos = listOf(bs("2026.11.01", doubleSet.todos[0].items + real)))
        m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), doubleSetReal, d)
        assertEquals(listOf("2026.11.01"), m.merged.todos.map { it.date })
        assertEquals(1, m.added)
        assertEquals(0, BackupMerger.merge(m.merged, doubleSetReal, d).added)
    }

    @Test
    fun `18 merge - 기기 안내 세트와 같은 날짜의 파일 항목`() {
        val guideAndReal = content(todos = listOf(bs(d, listOf(bi(g1, d), bi(g2, d), bi("진짜", d)))))
        var m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), guideAndReal, d)
        assertEquals(3, m.added)
        assertEquals(0, m.skipped)
        assertEquals(listOf(g1, g2, "진짜"), m.merged.todos[0].items.map { it.todo })
        val after = BackupMerger.merge(m.merged, guideAndReal, d)
        assertEquals(0, after.added)
        assertEquals(3, after.skipped)

        m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), content(todos = listOf(bs(d, listOf(bi("진짜", d))))), d)
        assertEquals(1, m.merged.todos.size)
        assertEquals(listOf("진짜"), m.merged.todos[0].items.map { it.todo })

        m = BackupMerger.merge(content(todos = listOf(bs(d, guides))), empty, d)
        assertEquals(0, m.added)
        assertEquals(listOf(bs(d, guides)), m.merged.todos)
    }

    // 19. 스토어 백업 연결

    @Test
    fun `19 store - 내보내기와 한 번에 저장, 다른 인스턴스가 다시 읽기`() {
        val storage = TodoStoreTest.InMemoryKeyValueStore()
        val store = TodoStore(storage)
        store.load()
        store.replaceAll(
            content(
                todos = listOf(bs("2026.11.06", listOf(bi("a", "2026.11.06", important = true)))),
                pinned = listOf(bi("p", "2026.11.01")),
            )
        )
        store.appendToArchive(listOf(TodoData(date = "2026.11.02", todo = "done")), "2026.11.05")
        val snapshot = store.backupContent()
        assertEquals(listOf(bs("2026.11.06", listOf(bi("a", "2026.11.06", important = true)))), snapshot.todos)
        assertEquals(listOf(bi("p", "2026.11.01")), snapshot.pinned)
        assertEquals(listOf(bs("2026.11.05", listOf(bi("done", "2026.11.02")))), snapshot.archive)

        val replacement = content(
            todos = listOf(bs("2026.11.07", listOf(bi("new", "2026.11.07")))),
            pinned = listOf(bi("np", "2026.11.03")),
            archive = listOf(bs("2026.11.04", listOf(bi("nd", "2026.11.03")))),
        )
        store.replaceAll(replacement)
        val other = TodoStore(storage)
        other.load()
        assertEquals(replacement, other.backupContent())
        assertTrue(other.pinnedDatas[0].isPinned)
        assertEquals(listOf("2026.11.07"), other.dateInfo)
    }

    @Test
    fun `안드로이드 - 가져온 항목은 서로 다른 id를 받는다`() {
        val storage = TodoStoreTest.InMemoryKeyValueStore()
        val store = TodoStore(storage)
        store.replaceAll(content(todos = listOf(bs(d, listOf(bi("운동", d), bi("운동", d)))), pinned = listOf(bi("운동", d))))
        val ids = store.todoDatas.flatten().map { it.id } + store.pinnedDatas.map { it.id }
        if (ids.toSet().size != ids.size) fail("중복 id: $ids")
    }
}
