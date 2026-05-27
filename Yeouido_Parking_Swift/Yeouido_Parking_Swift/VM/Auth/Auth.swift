import Foundation

enum AuthAPIError: LocalizedError {
    case notRegistered(String)
    case message(String)
    case invalidResponse
    case connection

    var errorDescription: String? {
        switch self {
        case .notRegistered(let message):
            return message
        case .message(let message):
            return message
        case .invalidResponse:
            return "서버 응답을 확인할 수 없습니다."
        case .connection:
            return "FastAPI 서버에 연결할 수 없습니다. 서버 실행과 주소를 확인해 주세요."
        }
    }
}

enum AuthAPI {
    static let baseURL = URL(string: "http://127.0.0.1:8000")!

    struct LoginRequest: Encodable {
        let user_email: String
        let user_password: String
    }

    struct SignupRequest: Encodable {
        let user_email: String
        let user_password: String
        let user_name: String?
        let user_phone: String
    }

    struct LoginResponse: Decodable {
        let status: String
        let userID: Int
        let userEmail: String
        let userName: String?
        let userPhone: String?
        let userDate: String?

        enum CodingKeys: String, CodingKey {
            case status
            case userID = "user_id"
            case userEmail = "user_email"
            case userName = "user_name"
            case userPhone = "user_phone"
            case userDate = "user_date"
        }
    }

    struct SignupResponse: Decodable {
        let status: String
    }

    private struct APIErrorResponse: Decodable {
        let detail: APIErrorDetail
    }

    private enum APIErrorDetail: Decodable {
        struct ValidationIssue: Decodable {
            let msg: String
        }

        case text(String)
        case validation([ValidationIssue])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let text = try? container.decode(String.self) {
                self = .text(text)
                return
            }

            if let validation = try? container.decode([ValidationIssue].self) {
                self = .validation(validation)
                return
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported error detail format."
            )
        }

        var message: String {
            switch self {
            case .text(let text):
                return text
            case .validation(let issues):
                return issues.first?.msg ?? "요청 처리에 실패했습니다."
            }
        }
    }

    static func login(email: String, password: String) async throws -> LoginResponse {
        try await request(
            path: "auth/login",
            body: LoginRequest(user_email: email, user_password: password),
            responseType: LoginResponse.self
        )
    }

    static func signup(email: String, password: String, name: String, phoneNumber: String) async throws -> SignupResponse {
        try await request(
            path: "auth/users",
            body: SignupRequest(
                user_email: email,
                user_password: password,
                user_name: name.isEmpty ? nil : name,
                user_phone: phoneNumber
            ),
            responseType: SignupResponse.self
        )
    }

    private static func request<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthAPIError.connection
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(responseType, from: data)
        }

        let detail = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).detail.message)
            ?? "요청 처리에 실패했습니다."

        if httpResponse.statusCode == 404 {
            throw AuthAPIError.notRegistered(detail)
        }

        throw AuthAPIError.message(detail)
    }
}

func normalizedEmail(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

func isValidEmail(_ value: String) -> Bool {
    value.range(
        of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
        options: .regularExpression
    ) != nil
}

func isValidSignupPassword(_ value: String) -> Bool {
    value.range(
        of: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$",
        options: .regularExpression
    ) != nil
}

func normalizedPhoneNumber(_ value: String) -> String {
    value.filter(\.isNumber)
}

func isValidPhoneNumber(_ value: String) -> Bool {
    let digits = normalizedPhoneNumber(value)
    return digits.range(
        of: #"^01(?:0|1|6|7|8|9)\d{7,8}$"#,
        options: .regularExpression
    ) != nil
}
