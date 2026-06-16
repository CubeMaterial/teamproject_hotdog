import Foundation

extension HotdogAPIClient {
    func login(userID: String, userPW: String) async throws -> LoginResponseDTO {
        let request = LoginRequest(userID: userID, userPW: userPW)
        do {
            return try await decodeLogin(path: "/auth/login", request: request)
        } catch let error as HotdogAPIError {
            if case let .httpError(statusCode, _) = error, statusCode == 404 {
                return try await decodeLogin(path: "/login", request: request)
            }
            throw error
        }
    }

    func signUp(
        userID: String,
        userPW: String,
        userName: String,
        userPhone: String?
    ) async throws -> LoginResponseDTO {
        let request = SignUpRequest(
            userID: userID,
            userPW: userPW,
            userName: userName,
            userPhone: userPhone
        )
        return try await decodeLogin(path: "/auth/signup", request: request)
    }

    func updateUserQuickPin(userSeq: Int, quickPinHash: String) async throws {
        let request = UpdateQuickPinRequest(quickPinHash: quickPinHash)
        do {
            _ = try await send(path: "/users/\(userSeq)/quick-pin", method: "PATCH", body: request)
        } catch let error as HotdogAPIError {
            if case let .httpError(statusCode, _) = error, statusCode == 404 {
                _ = try await send(path: "/users/\(userSeq)/pin", method: "PATCH", body: request)
                return
            }
            throw error
        }
    }

    func fetchUserProfile(userSeq: Int) async throws -> LoginResponseDTO {
        let data = try await send(path: "/users/\(userSeq)", method: "GET")
        return try decodeLoginResponse(data: data)
    }

    func checkUserIDAvailability(userID: String) async throws -> UserIDAvailabilityResponseDTO {
        let request = UserIDAvailabilityRequest(userID: userID)
        let candidates: [(path: String, method: String)] = [
            ("/auth/check-id", "POST"),
            ("/auth/check-user-id", "POST"),
            ("/users/check-id", "POST")
        ]

        var lastError: Error?
        for candidate in candidates {
            do {
                let data = try await send(path: candidate.path, method: candidate.method, body: request)
                return decodeAvailabilityResponse(from: data)
            } catch let error as HotdogAPIError {
                if case let .httpError(statusCode, body) = error {
                    if statusCode == 409 {
                        return UserIDAvailabilityResponseDTO(
                            available: false,
                            exists: true,
                            isDuplicate: true,
                            message: body.isEmpty ? "이미 사용 중인 아이디입니다." : body
                        )
                    }
                    if statusCode == 404 {
                        lastError = error
                        continue
                    }
                }
                throw error
            } catch {
                lastError = error
            }
        }

        if let lastError {
            throw lastError
        }
        throw HotdogAPIError.invalidResponse
    }

    func findUserID(userName: String, userPhone: String) async throws -> FindUserIDResponseDTO {
        let request = FindUserIDRequest(userName: userName, userPhone: userPhone)
        let data = try await send(path: "/auth/find-id", method: "POST", body: request)
        do {
            return try decoder.decode(FindUserIDResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func resetPassword(userID: String, userPW: String) async throws -> MessageResponseDTO {
        let request = ResetPasswordRequest(userID: userID, userPW: userPW)
        let data = try await send(path: "/auth/reset-password", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func sendEmailVerificationCode(email: String) async throws -> MessageResponseDTO {
        let request = EmailCodeRequest(email: email)
        let data = try await send(path: "/auth/email/send-code", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func verifyEmailCode(email: String, code: String) async throws -> MessageResponseDTO {
        let request = EmailCodeVerifyRequest(email: email, code: code)
        let data = try await send(path: "/auth/email/verify-code", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    private func decodeLogin(path: String, request: LoginRequest) async throws -> LoginResponseDTO {
        let data = try await send(path: path, method: "POST", body: request)
        return try decodeLoginResponse(data: data)
    }

    private func decodeLogin(path: String, request: SignUpRequest) async throws -> LoginResponseDTO {
        let data = try await send(path: path, method: "POST", body: request)
        return try decodeLoginResponse(data: data)
    }

    private func decodeLoginResponse(data: Data) throws -> LoginResponseDTO {
        do {
            if let value = try? decoder.decode(LoginResponseDTO.self, from: data) {
                return value
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<LoginResponseDTO>.self, from: data),
               let value = wrapped.value {
                return value
            }
            let wrapped = try decoder.decode(ListEnvelope<LoginResponseDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    private func decodeAvailabilityResponse(from data: Data) -> UserIDAvailabilityResponseDTO {
        if let value = try? decoder.decode(UserIDAvailabilityResponseDTO.self, from: data) {
            return value
        }
        if let message = try? decoder.decode(MessageResponseDTO.self, from: data) {
            return UserIDAvailabilityResponseDTO(
                available: true,
                exists: false,
                isDuplicate: false,
                message: message.message
            )
        }
        return UserIDAvailabilityResponseDTO(
            available: true,
            exists: false,
            isDuplicate: false,
            message: "사용 가능한 아이디입니다."
        )
    }
}
