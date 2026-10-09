//
//  String+Extensions.swift
//  TDT
//
//  Created by Yunjae Kim on 2026/09/16.
//

import Foundation

extension String {
    /// NSDataDetector가 찾은 http/https 링크의 (범위, URL) 목록
    var containedLinks: [(range: NSRange, url: URL)] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }

        let fullRange = NSRange(startIndex..., in: self)
        return detector.matches(in: self, options: [], range: fullRange)
            .compactMap { match in
                guard let url = match.url,
                      let scheme = url.scheme?.lowercased(),
                      scheme == "http" || scheme == "https"
                else { return nil }
                return (match.range, url)
            }
    }

    var firstContainedURL: URL? {
        containedLinks.first?.url
    }
}
