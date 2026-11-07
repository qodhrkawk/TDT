//
//  String+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/09/16.
//

import Foundation

extension String {
    /// NSDataDetector가 찾은 http/https 링크의 (범위, URL) 목록.
    /// 감지기는 "https://a.com에서"처럼 붙은 한글까지 국제 도메인으로 잡으므로,
    /// Android LinkDetector와 같게 ASCII 문자까지만 링크로 보고 끝 문장 부호를 뺀다
    var containedLinks: [(range: NSRange, url: URL)] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }

        let text = self as NSString
        let fullRange = NSRange(location: 0, length: text.length)
        return detector.matches(in: self, options: [], range: fullRange)
            .compactMap { match in
                guard let detected = match.url?.scheme?.lowercased(),
                      detected == "http" || detected == "https"
                else { return nil }

                let ascii = String(text.substring(with: match.range).prefix { $0.isASCII })
                let linkText = String.trimmingTrailingLinkPunctuation(ascii)
                guard !linkText.isEmpty, let url = String.linkURL(from: linkText) else { return nil }

                return (NSRange(location: match.range.location, length: (linkText as NSString).length), url)
            }
    }

    /// 문장 부호는 링크에서 뺀다. 닫는 괄호는 링크 안에 짝이 있을 때만 남긴다
    private static func trimmingTrailingLinkPunctuation(_ raw: String) -> String {
        var text = raw
        while let last = text.last {
            let strip: Bool
            switch last {
            case ".", ",", ";", ":", "!", "?", "'": strip = true
            case ")": strip = text.filter { $0 == ")" }.count > text.filter { $0 == "(" }.count
            case "]": strip = text.filter { $0 == "]" }.count > text.filter { $0 == "[" }.count
            default: strip = false
            }
            guard strip else { break }
            text.removeLast()
        }
        return text
    }

    /// scheme이 없으면 http://를 붙이고, scheme은 소문자로 맞춘다
    private static func linkURL(from linkText: String) -> URL? {
        let urlString: String
        if let separator = linkText.range(of: "://") {
            urlString = linkText[..<separator.lowerBound].lowercased() + linkText[separator.lowerBound...]
        } else {
            urlString = "http://" + linkText
        }
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    /// 공백과 줄바꿈뿐인 문자열인지
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var firstContainedURL: URL? {
        containedLinks.first?.url
    }
}
