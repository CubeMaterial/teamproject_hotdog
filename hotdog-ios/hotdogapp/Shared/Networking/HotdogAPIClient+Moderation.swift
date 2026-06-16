import Foundation

extension HotdogAPIClient {
    func predictCurse(text: String) async throws -> CursePredictionResponseDTO {
        let request = CursePredictionRequest(text: text)
        let data = try await sendDogAnalysisAPI(path: "/curse/predict", method: "POST", body: request)
        do {
            return try decoder.decode(CursePredictionResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }
}
