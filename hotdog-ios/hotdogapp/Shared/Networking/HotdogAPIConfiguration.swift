import Foundation

enum APIConfiguration {
    static let defaultBaseURLString = "http://127.0.0.1:8000"

    static var baseURLString: String {
        ProcessInfo.processInfo.environment["HOTDOG_API_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? defaultBaseURLString
    }

    static func absoluteURLString(path: String) -> String? {
        URL(string: baseURLString)?
            .appending(path: path)
            .absoluteString
    }
}

enum DogAnalysisAPIConfiguration {
    static let defaultBaseURLString = "http://127.0.0.1:8000"

    static var apiKey: String? {
        ProcessInfo.processInfo.environment["HOTDOG_DOG_ANALYSIS_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    static var baseURLStrings: [String] {
        let override = ProcessInfo.processInfo.environment["HOTDOG_DOG_ANALYSIS_API_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [
            override?.isEmpty == false ? override : nil,
            APIConfiguration.baseURLString,
            defaultBaseURLString
        ].compactMap { $0 }

        return candidates.removingDuplicates()
    }
}

enum ChatbotAPIConfiguration {
    static let defaultBaseURLString = "http://127.0.0.1:8001"

    static var baseURLStrings: [String] {
        let override = ProcessInfo.processInfo.environment["HOTDOG_CHATBOT_API_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [
            override?.isEmpty == false ? override : nil,
            APIConfiguration.baseURLString,
            defaultBaseURLString
        ].compactMap { $0 }

        return candidates.removingDuplicates()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        reduce(into: [Element]()) { result, element in
            guard !result.contains(element) else { return }
            result.append(element)
        }
    }
}
