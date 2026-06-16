import Foundation

extension HotdogAPIClient {
    func sendChatMessage(
        message: String,
        sessionID: String?,
        userSeq: Int?,
        userID: String?,
        buySeq: Int? = nil,
        deliverSeq: Int? = nil,
        productSeq: Int? = nil
    ) async throws -> ChatMessageResponseDTO {
        let request = ChatMessageRequest(
            message: message,
            sessionID: sessionID,
            userSeq: userSeq,
            userID: userID,
            buySeq: buySeq,
            deliverSeq: deliverSeq,
            productSeq: productSeq
        )
        let data = try await sendChatbotAPI(path: "/chat/message", method: "POST", body: request)
        do {
            return try decoder.decode(ChatMessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchChatbotOptions() async throws -> ChatOptionsResponseDTO {
        let data = try await sendChatbotAPI(path: "/chat/options", method: "GET", body: Optional<String>.none)
        do {
            return try decoder.decode(ChatOptionsResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func selectChatbotOption(_ selected: String) async throws -> ChatSelectResponseDTO {
        let request = ChatSelectRequest(selected: selected)
        let data = try await sendChatbotAPI(path: "/chat/select", method: "POST", body: request)
        do {
            return try decoder.decode(ChatSelectResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }
}
