package com.qodhrkawk.flick.data

/** 메모 속 링크 하나. [range]는 원문 기준 위치, [url]은 바로 열 수 있는 http/https 주소 */
data class ContainedLink(val range: IntRange, val url: String)

/**
 * iOS `String+Extensions.swift`(NSDataDetector, http/https만) 대응.
 * NSDataDetector처럼 scheme 없는 주소(naver.com)도 잡고 http://를 붙인다.
 * URL은 ASCII 문자까지만 이어 "https://a.com/b에서"의 조사를 포함하지 않는다.
 * Android 클래스에 의존하지 않아 JVM 유닛 테스트가 가능하다.
 */
private const val URL_CHARS = "A-Za-z0-9\\-._~:/?#\\[\\]@!\\$\\&'()*+,;=%"
private const val TLDS =
    "com|net|org|edu|gov|kr|io|co|me|ai|app|dev|ly|gg|tv|to|info|biz|xyz|site|shop|jp|cn|uk|de|fr|us"

private val LINK_PATTERN = Regex(
    "(?<![A-Za-z0-9._%+@/\\-])" +
        "(?:" +
        "https?://[A-Za-z0-9\\[][$URL_CHARS]*" +
        "|" +
        "(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]*[A-Za-z0-9])?\\.)+(?:$TLDS)" +
        "(?![A-Za-z0-9_@\\-]|\\.[A-Za-z0-9])" +
        "(?::\\d{1,5})?(?:[/?#][$URL_CHARS]*)?" +
        ")",
    RegexOption.IGNORE_CASE,
)

fun String.containedLinks(): List<ContainedLink> =
    LINK_PATTERN.findAll(this).map { match ->
        val text = trimTrailingPunctuation(match.value)
        ContainedLink(
            range = match.range.first until match.range.first + text.length,
            url = normalizeUrl(text),
        )
    }.toList()

val String.firstContainedUrl: String?
    get() = containedLinks().firstOrNull()?.url

/** 문장 부호는 링크에서 뺀다. 닫는 괄호는 URL 안에 짝이 있을 때만 남긴다 */
private fun trimTrailingPunctuation(raw: String): String {
    var end = raw.length
    while (end > 0) {
        val strip = when (raw[end - 1]) {
            '.', ',', ';', ':', '!', '?', '\'' -> true
            ')' -> isUnbalanced(raw, end, '(', ')')
            ']' -> isUnbalanced(raw, end, '[', ']')
            else -> false
        }
        if (!strip) break
        end -= 1
    }
    return raw.substring(0, end)
}

private fun isUnbalanced(raw: String, end: Int, open: Char, close: Char): Boolean {
    val text = raw.substring(0, end)
    return text.count { it == close } > text.count { it == open }
}

/** 인텐트의 scheme 매칭은 대소문자를 구분하므로 소문자로 맞춘다 */
private fun normalizeUrl(text: String): String {
    val separator = text.indexOf("://")
    if (separator == -1) return "http://$text"
    return text.substring(0, separator).lowercase() + text.substring(separator)
}
