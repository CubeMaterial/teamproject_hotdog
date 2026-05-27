//
//  ParkingAvailabilityService.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import Foundation

enum ParkingAvailabilityService {
    static func fetchYeouidoAvailability() async throws -> [String: Int] {
        guard let url = URL(string: "https://www.ihangangpark.kr/parking/region/region8") else {
            throw ParkingAvailabilityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParkingAvailabilityError.invalidHTML
        }

        return parseAvailability(from: html)
    }

    private static func parseAvailability(from html: String) -> [String: Int] {
        let pattern = #"<tr>\s*<td><span>(여의도[1-5]주차장)\s*</span></td>[\s\S]*?<td><span class="highlight-blue bold">[\s\S]*?(\d+)[\s\S]*?</span></td>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [:]
        }

        let nsRange = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)

        var availability: [String: Int] = [:]

        for match in matches {
            guard
                let nameRange = Range(match.range(at: 1), in: html),
                let countRange = Range(match.range(at: 2), in: html),
                let count = Int(html[countRange])
            else {
                continue
            }

            let parkingName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            availability[parkingName] = count
        }

        return availability
    }
}

private enum ParkingAvailabilityError: Error {
    case invalidURL
    case invalidHTML
}
