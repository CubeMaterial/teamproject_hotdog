//
//  FestivalService.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import Foundation

enum FestivalService {
    private static let baseURLString = "https://hangang.seoul.go.kr"
    private static let yeouidoFestivalListURLString = "https://hangang.seoul.go.kr/www/eventMng/list.do?srchType=list&evntSn=&mid=538&pageNo=1&keyword=&opt4=Hzone007&opt11=&opt12=&opt13=&opt14="

    static func fetchYeouidoFestivals() async throws -> [FestivalItem] {
        guard let url = URL(string: yeouidoFestivalListURLString) else {
            throw FestivalServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw FestivalServiceError.invalidHTML
        }

        return parseFestivals(from: html)
    }

    private static func parseFestivals(from html: String) -> [FestivalItem] {
        let pattern = #"<li class="list-item">[\s\S]*?<a href="javascript:goDetail\('(\d+)'\)" title="([^"]*)">[\s\S]*?<img src="([^"]*)"[\s\S]*?<a href="javascript:goDetail\('\d+'\)" class="event-tit" title="[^"]*"><strong>([^<]*)</strong></a>[\s\S]*?<dt>기간</dt>\s*<dd>([^<]*)</dd>[\s\S]*?<dt>시간</dt>\s*<dd>([^<]*)</dd>[\s\S]*?<dt>참여</dt>\s*<dd>([^<]*)</dd>[\s\S]*?<dt>장소</dt>\s*<dd>([^<]*)</dd>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsRange = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)

        return matches.compactMap { match in
            guard
                let eventIDRange = Range(match.range(at: 1), in: html),
                let imageRange = Range(match.range(at: 3), in: html),
                let titleRange = Range(match.range(at: 4), in: html),
                let periodRange = Range(match.range(at: 5), in: html),
                let timeRange = Range(match.range(at: 6), in: html),
                let placeRange = Range(match.range(at: 8), in: html)
            else {
                return nil
            }

            let eventID = String(html[eventIDRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let title = cleanText(String(html[titleRange]))
            let period = cleanText(String(html[periodRange]))
            let time = cleanText(String(html[timeRange]))
            let place = cleanText(String(html[placeRange]))

            let subtitle = "\(period) · \(time)"
            let detailText = place.isEmpty ? subtitle : "\(subtitle) · \(place)"

            return FestivalItem(
                title: title,
                subtitle: detailText,
                imageName: nil,
                imageURL: absoluteURL(from: String(html[imageRange])),
                detailURL: URL(string: "\(baseURLString)/www/eventMng/view.do?evntSn=\(eventID)&mid=538")
            )
        }
    }

    private static func absoluteURL(from path: String) -> URL? {
        let trimmedPath = cleanText(path)

        if trimmedPath.hasPrefix("http"), let url = URL(string: trimmedPath) {
            return url
        }

        return URL(string: baseURLString + trimmedPath)
    }

    private static func cleanText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum FestivalServiceError: Error {
    case invalidURL
    case invalidHTML
}
