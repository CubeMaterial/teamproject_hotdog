//
//  Weight.swift
//  Yeouido_Parking_Swift
//
//  Created by Restitutor on 4/12/26.
//

import Foundation

let hours = (7...22).map { String(format: "%02d", $0) }

struct TrafficRow {
    let date: Date
    let traffic: [String: Double] // keys: "07"..."22"
}

func isoWeekday(_ date: Date, calendar: Calendar = .current) -> Int {
    let w = calendar.component(.weekday, from: date) // Sun=1...Sat=7
    return w == 1 ? 7 : w - 1                  // Mon=1...Sun=7
}

func median(_ values: [Double]) -> Double {
    let s = values.sorted()
    let m = s.count / 2
    return s.count.isMultiple(of: 2) ? (s[m - 1] + s[m]) / 2 : s[m]
}

// Preprocess traffic rows into weekday/hour weights.
func buildWeekdayWeights(_ rows: [TrafficRow], calendar: Calendar = .current) -> [Int: [String: Double]] {
    var buckets = [Int: [String: [Double]]]()

    for row in rows {
        let day = isoWeekday(row.date, calendar: calendar)
        for h in hours {
            if let v = row.traffic[h] {
                buckets[day, default: [:]][h, default: []].append(v)
            }
        }
    }

    var result = [Int: [String: Double]]()
    for day in 1...7 {
        guard let byHour = buckets[day],
              hours.allSatisfy({ !(byHour[$0]?.isEmpty ?? true) }) else { continue }

        let med = Dictionary(uniqueKeysWithValues: hours.map { ($0, median(byHour[$0]!)) })
        let minV = med.values.min()!
        let maxV = med.values.max()!

        let scaled = Dictionary(uniqueKeysWithValues: hours.map { h in
            (h, maxV == minV ? 1.0 : (med[h]! - minV) / (maxV - minV))
        })

        let sum = scaled.values.reduce(0, +)
        result[day] = Dictionary(uniqueKeysWithValues: hours.map { h in
            (h, sum > 0 ? scaled[h]! / sum : 1.0 / Double(hours.count))
        })
    }
    return result
}

private func repairedAnchorWeight(for hour: String, in weights: [String: Double]) -> Double {
    let eps = 1e-9

    if let value = weights[hour], value > 0 {
        return value
    }

    guard let anchorIndex = hours.firstIndex(of: hour) else {
        return eps
    }

    var previousPositive: (index: Int, value: Double)?
    for index in stride(from: anchorIndex - 1, through: 0, by: -1) {
        let candidateHour = hours[index]
        if let value = weights[candidateHour], value > 0 {
            previousPositive = (index, value)
            break
        }
    }

    var nextPositive: (index: Int, value: Double)?
    for index in (anchorIndex + 1)..<hours.count {
        let candidateHour = hours[index]
        if let value = weights[candidateHour], value > 0 {
            nextPositive = (index, value)
            break
        }
    }

    switch (previousPositive, nextPositive) {
    case let (.some(previous), .some(next)):
        let distance = Double(next.index - previous.index)
        guard distance > 0 else { return max(previous.value, eps) }
        let progress = Double(anchorIndex - previous.index) / distance
        let interpolated = previous.value + ((next.value - previous.value) * progress)
        return max(interpolated, eps)
    case let (.some(previous), nil):
        return max(previous.value, eps)
    case let (nil, .some(next)):
        return max(next.value, eps)
    case (nil, nil):
        return eps
    }
}

// Runtime: one anchor count -> all hours.
func estimateParking(
    target: [String: Int],
    maxCapacity: Int,
    weekday: Int,
    weightsByWeekday: [Int: [String: Double]]
) -> [String: Int] {
    guard let anchor = target.first,
          hours.contains(anchor.key),
          let weights = weightsByWeekday[weekday] else { return [:] }

    let anchorWeight = repairedAnchorWeight(for: anchor.key, in: weights)

    return Dictionary(uniqueKeysWithValues: hours.map { h in
        let targetWeight = Swift.max(weights[h] ?? 0, 0)
        let raw = Double(anchor.value) * targetWeight / anchorWeight
        let clamped = Swift.min(Double(maxCapacity), Swift.max(0, raw))
        return (h, Int(clamped.rounded()))
    })
}

// Example
//let weightsByWeekday = buildWeekdayWeights(rows2025)
//let result = estimateParking(
//    target: ["13": 125],
//    maxCapacity: 670,
//    weekday: 1, // Monday
//    weightsByWeekday: weightsByWeekday
//)
// MARK: - Prediction System

enum WeightPredictionError: Error {
    case invalidHeader
    case invalidData
    case invalidAnchorHour
    case invalidWeights
}

struct WeightPredictionInput {
    let date: Date
    let anchorHour: String
    let anchorCount: Int
    let maxCapacity: Int
}

private struct WeightPresetFile: Decodable {
    struct Metadata: Decodable {
        let location: String?
        let base: String?
        let hours: [String]
        let weekdayBasis: String?
        let holidayBasis: String?

        enum CodingKeys: String, CodingKey {
            case location
            case base
            case hours
            case weekdayBasis = "weekday_basis"
            case holidayBasis = "holiday_basis"
        }
    }

    struct Profiles: Decodable {
        let weekday: [String: Double]
        let holiday: [String: Double]
    }

    let metadata: Metadata
    let weights: Profiles
}

struct WeightPredictionEngine {
    private let calendar: Calendar
    private let weightsByWeekday: [Int: [String: Double]]
    private let treatFixedHolidaysAsHoliday: Bool

    init(rows: [TrafficRow], calendar: Calendar = .current) {
        self.calendar = calendar
        self.weightsByWeekday = buildWeekdayWeights(rows, calendar: calendar)
        self.treatFixedHolidaysAsHoliday = false
    }

    private init(
        weightsByWeekday: [Int: [String: Double]],
        calendar: Calendar = .current,
        treatFixedHolidaysAsHoliday: Bool = false
    ) {
        self.calendar = calendar
        self.weightsByWeekday = weightsByWeekday
        self.treatFixedHolidaysAsHoliday = treatFixedHolidaysAsHoliday
    }

    /// `weight.csv` 같은 리소스 파일을 읽어 예측 엔진을 생성한다.
    /// CSV 형식:
    /// date,07,08,...,22
    /// 2025-01-01,12,14,...,8
    static func makeFromCSV(
        url: URL,
        calendar: Calendar = .current
    ) throws -> WeightPredictionEngine {
        let text = try String(contentsOf: url, encoding: .utf8)
        let rows = try parseCSV(text)
        return WeightPredictionEngine(rows: rows, calendar: calendar)
    }

    static func makeFromJSON(
        url: URL,
        calendar: Calendar = .current
    ) throws -> WeightPredictionEngine {
        let data = try Data(contentsOf: url)
        let preset = try JSONDecoder().decode(WeightPresetFile.self, from: data)
        let weightsByWeekday = try makeWeightsByWeekday(from: preset)
        return WeightPredictionEngine(
            weightsByWeekday: weightsByWeekday,
            calendar: calendar,
            treatFixedHolidaysAsHoliday: true
        )
    }

    /// 기본 엔진은 번들 JSON을 우선 사용하고, 실패하면 샘플 프로필로 폴백한다.
    static func makeDefault(calendar: Calendar = .current) -> WeightPredictionEngine {
        if let bundledURL = bundledWeightsURL(),
           let engine = try? makeFromJSON(url: bundledURL, calendar: calendar) {
            return engine
        }

        if let sourceURL = sourceWeightsURL(),
           let engine = try? makeFromJSON(url: sourceURL, calendar: calendar) {
            return engine
        }

        return WeightPredictionEngine(rows: makeSampleRows(calendar: calendar), calendar: calendar)
    }

    func predict(_ input: WeightPredictionInput) throws -> [String: Int] {
        guard hours.contains(input.anchorHour) else {
            throw WeightPredictionError.invalidAnchorHour
        }

        let weekday = predictionWeekday(for: input.date)
        return estimateParking(
            target: [input.anchorHour: input.anchorCount],
            maxCapacity: input.maxCapacity,
            weekday: weekday,
            weightsByWeekday: weightsByWeekday
        )
    }

    func predict(
        date: Date,
        anchorHour: String,
        anchorCount: Int,
        maxCapacity: Int
    ) throws -> [String: Int] {
        try predict(
            WeightPredictionInput(
                date: date,
                anchorHour: anchorHour,
                anchorCount: anchorCount,
                maxCapacity: maxCapacity
            )
        )
    }
}

private extension WeightPredictionEngine {
    func predictionWeekday(for date: Date) -> Int {
        if treatFixedHolidaysAsHoliday,
           Self.isFixedHoliday(date, calendar: calendar) {
            return 7
        }

        return isoWeekday(date, calendar: calendar)
    }

    static func makeWeightsByWeekday(from preset: WeightPresetFile) throws -> [Int: [String: Double]] {
        let declaredHours = Set(preset.metadata.hours)
        guard Set(hours).isSubset(of: declaredHours) else {
            throw WeightPredictionError.invalidWeights
        }

        let weekdayWeights = try validatedProfile(preset.weights.weekday)
        let holidayWeights = try validatedProfile(preset.weights.holiday)

        var output: [Int: [String: Double]] = [:]
        for day in 1...5 {
            output[day] = weekdayWeights
        }
        output[6] = holidayWeights
        output[7] = holidayWeights

        return output
    }

    static func validatedProfile(_ rawProfile: [String: Double]) throws -> [String: Double] {
        let profile = Dictionary(uniqueKeysWithValues: hours.map { hour in
            (hour, Swift.max(rawProfile[hour] ?? -1, 0))
        })

        guard hours.allSatisfy({ rawProfile[$0] != nil }),
              profile.values.contains(where: { $0 > 0 }) else {
            throw WeightPredictionError.invalidWeights
        }

        return profile
    }

    static func bundledWeightsURL() -> URL? {
        if let rootURL = Bundle.main.url(forResource: "yeouido_weights_2024", withExtension: "json") {
            return rootURL
        }

        return Bundle.main.url(
            forResource: "yeouido_weights_2024",
            withExtension: "json",
            subdirectory: "VM"
        )
    }

    static func sourceWeightsURL() -> URL? {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("yeouido_weights_2024.json")

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    static func isFixedHoliday(_ date: Date, calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return false
        }

        return Set([
            "1-1",
            "3-1",
            "5-5",
            "6-6",
            "8-15",
            "10-3",
            "10-9",
            "12-25"
        ]).contains("\(month)-\(day)")
    }

    static func parseCSV(_ text: String) throws -> [TrafficRow] {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let header = lines.first else { return [] }
        let headerColumns = header.split(separator: ",").map { String($0) }
        let expectedHeader = ["date"] + hours
        guard headerColumns.count >= expectedHeader.count else {
            throw WeightPredictionError.invalidHeader
        }

        let normalizedHeader = headerColumns.prefix(expectedHeader.count).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard normalizedHeader == expectedHeader else {
            throw WeightPredictionError.invalidHeader
        }

        var output: [TrafficRow] = []
        for line in lines.dropFirst() {
            let columns = line.split(separator: ",", omittingEmptySubsequences: false).map {
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard columns.count >= expectedHeader.count else {
                throw WeightPredictionError.invalidData
            }

            guard let date = parseDate(columns[0]) else {
                throw WeightPredictionError.invalidData
            }

            var traffic: [String: Double] = [:]
            for (index, hour) in hours.enumerated() {
                let valueIndex = index + 1
                guard let value = Double(columns[valueIndex]) else {
                    throw WeightPredictionError.invalidData
                }
                traffic[hour] = value
            }

            output.append(TrafficRow(date: date, traffic: traffic))
        }

        return output
    }

    static func parseDate(_ value: String) -> Date? {
        let formats = [
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy-MM-dd HH:mm:ss"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    static func makeSampleRows(calendar: Calendar) -> [TrafficRow] {
        var rows: [TrafficRow] = []
        let base = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()

        // 8주치 샘플(56일)로 폴백용 패턴을 만든다.
        for offset in 0..<56 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: base) else { continue }
            let weekday = isoWeekday(date, calendar: calendar)
            let profile = weekdayProfile(for: weekday)

            let dailyFactor = 1.0 + (Double((offset % 5) - 2) * 0.02)
            let traffic = Dictionary(uniqueKeysWithValues: hours.map { hour in
                let value = (profile[hour] ?? 0.0) * dailyFactor
                return (hour, max(0.0, value))
            })

            rows.append(TrafficRow(date: date, traffic: traffic))
        }

        return rows
    }

    static func weekdayProfile(for weekday: Int) -> [String: Double] {
        func makeProfile(_ pairs: [(String, Double)]) -> [String: Double] {
            let base = Dictionary(uniqueKeysWithValues: hours.map { ($0, 0.2) })
            return pairs.reduce(into: base) { partialResult, pair in
                partialResult[pair.0] = pair.1
            }
        }

        switch weekday {
        case 1, 2, 3, 4: // 평일(월~목)
            return makeProfile([
                ("07", 0.35), ("08", 0.55), ("09", 0.75), ("10", 0.68),
                ("11", 0.72), ("12", 0.85), ("13", 1.00), ("14", 0.92),
                ("15", 0.88), ("16", 0.94), ("17", 0.98), ("18", 0.90),
                ("19", 0.78), ("20", 0.60), ("21", 0.45), ("22", 0.32)
            ])
        case 5: // 금요일
            return makeProfile([
                ("07", 0.30), ("08", 0.48), ("09", 0.62), ("10", 0.66),
                ("11", 0.76), ("12", 0.90), ("13", 1.00), ("14", 0.96),
                ("15", 0.93), ("16", 0.95), ("17", 0.97), ("18", 0.92),
                ("19", 0.88), ("20", 0.74), ("21", 0.56), ("22", 0.40)
            ])
        case 6: // 토요일
            return makeProfile([
                ("07", 0.22), ("08", 0.25), ("09", 0.35), ("10", 0.52),
                ("11", 0.72), ("12", 0.90), ("13", 1.00), ("14", 0.98),
                ("15", 0.90), ("16", 0.86), ("17", 0.82), ("18", 0.76),
                ("19", 0.68), ("20", 0.58), ("21", 0.44), ("22", 0.30)
            ])
        default: // 일요일
            return makeProfile([
                ("07", 0.18), ("08", 0.20), ("09", 0.28), ("10", 0.44),
                ("11", 0.62), ("12", 0.78), ("13", 0.90), ("14", 0.88),
                ("15", 0.82), ("16", 0.74), ("17", 0.66), ("18", 0.58),
                ("19", 0.50), ("20", 0.42), ("21", 0.32), ("22", 0.22)
            ])
        }
    }
}
