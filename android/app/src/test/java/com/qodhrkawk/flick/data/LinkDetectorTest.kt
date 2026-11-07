package com.qodhrkawk.flick.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** iOS `containedLinks`/`firstContainedURL` 동작과 한글 메모 경계 검증 */
class LinkDetectorTest {

    private fun urls(text: String) = text.containedLinks().map { it.url }
    private fun matched(text: String) = text.containedLinks().map { text.substring(it.range) }

    @Test
    fun `http와 https 링크를 찾고 범위를 돌려준다`() {
        val text = "참고 https://flick.app/a?b=1 끝"
        assertEquals(listOf("https://flick.app/a?b=1"), matched(text))
        assertEquals(listOf("https://flick.app/a?b=1"), urls(text))
    }

    @Test
    fun `링크가 없으면 비어 있다`() {
        assertEquals(emptyList<String>(), urls("장보기 1.5kg, v3.0.1 확인"))
        assertNull("그냥 메모".firstContainedUrl)
    }

    @Test
    fun `여러 개면 첫 링크가 firstContainedUrl`() {
        val text = "http://a.com 그리고 https://b.com"
        assertEquals(listOf("http://a.com", "https://b.com"), urls(text))
        assertEquals("http://a.com", text.firstContainedUrl)
    }

    @Test
    fun `scheme 없는 주소는 http를 붙인다`() {
        assertEquals(listOf("http://www.naver.com"), urls("www.naver.com 보기"))
        assertEquals(listOf("http://naver.co.kr/news"), urls("naver.co.kr/news"))
    }

    @Test
    fun `한글 조사와 줄바꿈에서 링크가 끝난다`() {
        assertEquals(listOf("https://a.com/b"), matched("https://a.com/b에서 확인"))
        assertEquals(listOf("naver.com"), matched("naver.com에서 확인"))
        assertEquals(listOf("https://a.com", "https://b.com"), matched("https://a.com\nhttps://b.com"))
    }

    @Test
    fun `끝 문장 부호는 빼고 짝이 있는 괄호는 남긴다`() {
        assertEquals(listOf("https://a.com/b"), matched("https://a.com/b."))
        assertEquals(listOf("https://a.com/b"), matched("(https://a.com/b)"))
        assertEquals(
            listOf("https://en.wikipedia.org/wiki/A_(b)"),
            matched("https://en.wikipedia.org/wiki/A_(b),"),
        )
    }

    @Test
    fun `이메일과 다른 scheme과 파일명은 링크가 아니다`() {
        assertEquals(emptyList<String>(), urls("foo@bar.com"))
        assertEquals(emptyList<String>(), urls("mailto:foo@bar.com"))
        assertEquals(emptyList<String>(), urls("ftp://files.com/a"))
        assertEquals(emptyList<String>(), urls("report.txt"))
        assertEquals(emptyList<String>(), urls("foo.com.txt"))
        assertEquals(emptyList<String>(), urls("example.community"))
    }

    @Test
    fun `대문자 scheme은 소문자로 맞추되 범위는 원문 그대로`() {
        val text = "HTTPS://Flick.app/Path"
        assertEquals(listOf("https://Flick.app/Path"), urls(text))
        assertEquals(listOf(text), matched(text))
    }
}
