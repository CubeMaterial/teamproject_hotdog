import Foundation

struct HotdogAPIClient {
    private let session: URLSession
    let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
    }

    func send(path: String, method: String) async throws -> Data {
        try await send(path: path, method: method, body: Optional<String>.none)
    }

    func send<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        try await send(
            path: path,
            method: method,
            body: body,
            baseURLString: APIConfiguration.baseURLString
        )
    }

    func send<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        baseURLString: String,
        extraHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval? = nil
    ) async throws -> Data {
        guard let baseURL = URL(string: baseURLString) else {
            throw HotdogAPIError.invalidBaseURL(baseURLString)
        }

        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        extraHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw HotdogAPIError.transport(urlError)
        } catch {
            throw HotdogAPIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HotdogAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
            throw HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
        }

        return data
    }

    func sendChatbotAPI<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        var lastError: Error?

        for baseURLString in ChatbotAPIConfiguration.baseURLStrings {
            do {
                return try await send(
                    path: path,
                    method: method,
                    body: body,
                    baseURLString: baseURLString,
                    extraHeaders: ["ngrok-skip-browser-warning": "true"],
                    timeoutInterval: 150
                )
            } catch {
                lastError = error
            }
        }

        throw lastError ?? HotdogAPIError.invalidBaseURL(ChatbotAPIConfiguration.defaultBaseURLString)
    }

    func sendDogAnalysisAPI<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        var lastError: Error?

        for baseURLString in DogAnalysisAPIConfiguration.baseURLStrings {
            guard let baseURL = URL(string: baseURLString) else {
                lastError = HotdogAPIError.invalidBaseURL(baseURLString)
                continue
            }

            let url = baseURL.appending(path: path)
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            if let apiKey = DogAnalysisAPIConfiguration.apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            }

            if let body {
                request.httpBody = try encoder.encode(body)
            }

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let urlError as URLError {
                lastError = HotdogAPIError.transport(urlError)
                continue
            } catch {
                lastError = HotdogAPIError.unknown(error)
                continue
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = HotdogAPIError.invalidResponse
                continue
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
                lastError = HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
                continue
            }

            return data
        }

        throw lastError ?? HotdogAPIError.invalidBaseURL(DogAnalysisAPIConfiguration.defaultBaseURLString)
    }

    func uploadDogAnalysisImage(path: String, imageData: Data, queryItems: [URLQueryItem] = []) async throws -> Data {
        var lastError: Error?

        for baseURLString in DogAnalysisAPIConfiguration.baseURLStrings {
            guard let baseURL = URL(string: baseURLString) else {
                lastError = HotdogAPIError.invalidBaseURL(baseURLString)
                continue
            }

            let boundary = "Boundary-\(UUID().uuidString)"
            let url = baseURL.appending(path: path).appending(queryItems: queryItems)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 120
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            if let apiKey = DogAnalysisAPIConfiguration.apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            }
            request.httpBody = multipartImageBody(
                imageData: imageData,
                boundary: boundary,
                fieldName: "image",
                filename: "dog.jpg"
            )

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let urlError as URLError {
                lastError = HotdogAPIError.transport(urlError)
                continue
            } catch {
                lastError = HotdogAPIError.unknown(error)
                continue
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = HotdogAPIError.invalidResponse
                continue
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
                lastError = HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
                continue
            }

            return data
        }

        throw lastError ?? HotdogAPIError.invalidBaseURL(DogAnalysisAPIConfiguration.defaultBaseURLString)
    }

    private func multipartImageBody(imageData: Data, boundary: String, fieldName: String, filename: String) -> Data {
        var body = Data()
        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        body.appendUTF8("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendUTF8("\r\n")
        body.appendUTF8("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
