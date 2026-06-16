import Foundation

enum HotdogAPIError: LocalizedError {
    case invalidBaseURL(String)
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case transport(URLError)
    case decoding(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case let .invalidBaseURL(urlString):
            return "API 주소가 올바르지 않습니다: \(urlString)"
        case .invalidResponse:
            return "서버 응답 형식이 올바르지 않습니다."
        case let .httpError(statusCode, body):
            return "서버 오류(\(statusCode)): \(body)"
        case let .transport(error):
            return "네트워크 연결 오류: \(error.localizedDescription)"
        case let .decoding(error):
            return "응답 파싱 실패: \(error.localizedDescription)"
        case let .unknown(error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}
