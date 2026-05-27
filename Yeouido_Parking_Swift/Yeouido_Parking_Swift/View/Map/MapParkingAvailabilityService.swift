//
//  ParkingAvailabilityService.swift
//  Yeouido_Parking_Swift
//

import Foundation

final class MapParkingAvailabilityService: NSObject {
    static let shared = MapParkingAvailabilityService()

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private override init() {}

    func fetchAvailabilities() async throws -> [String: ParkingAvailability] {
        let url = URL(string: "https://www.ihangangpark.kr/parking/region/region8")!
        let (data, _) = try await session.data(from: url)
        let html = String(decoding: data, as: UTF8.self)
        return try parseAvailabilities(from: html)
    }

    private func parseAvailabilities(from html: String) throws -> [String: ParkingAvailability] {
        let pattern = #"<tr>\s*<td><span>\s*(여의도\d주차장)\s*</span></td>\s*<td><span>\s*([^<]+?)\s*</span></td>\s*<td><button[^>]*>길찾기</button></td>.*?<td><span class="highlight-blue bold">\s*([0-9,]+)\s*</span></td>\s*<td><span>\s*([0-9,]+)\s*</span></td>"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        var results: [String: ParkingAvailability] = [:]

        for match in matches {
            guard
                let nameRange = Range(match.range(at: 1), in: html),
                let availableRange = Range(match.range(at: 3), in: html),
                let totalRange = Range(match.range(at: 4), in: html)
            else {
                continue
            }

            let sourceName = html[nameRange].trimmingCharacters(in: .whitespacesAndNewlines)
            let availableText = html[availableRange].replacingOccurrences(of: ",", with: "")
            let totalText = html[totalRange].replacingOccurrences(of: ",", with: "")

            guard
                let availableSpots = Int(availableText),
                let totalSpots = Int(totalText)
            else {
                continue
            }

            results[sourceName] = ParkingAvailability(
                sourceName: sourceName,
                availableSpots: availableSpots,
                totalSpots: totalSpots
            )
        }

        if results.isEmpty {
            throw NSError(
                domain: "MapParkingAvailabilityService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "주차장 잔여 대수를 파싱하지 못했습니다."]
            )
        }

        return results
    }
}

extension MapParkingAvailabilityService: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
