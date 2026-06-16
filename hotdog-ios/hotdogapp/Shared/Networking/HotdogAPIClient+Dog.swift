import Foundation

extension HotdogAPIClient {
    func predictDogBreed(imageData: Data, topK: Int = 3, removeBackground: Bool = true) async throws -> DogBreedPredictionDTO {
        let queryItems = [
            URLQueryItem(name: "top_k", value: "\(topK)"),
            URLQueryItem(name: "remove_background", value: removeBackground ? "true" : "false")
        ]
        let data = try await uploadDogAnalysisImage(path: "/breed/predict", imageData: imageData, queryItems: queryItems)
        do {
            return try decoder.decode(DogBreedPredictionDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func extractDogColor(imageData: Data) async throws -> DogColorExtractionDTO {
        let data = try await uploadDogAnalysisImage(path: "/color/extract", imageData: imageData)
        do {
            return try decoder.decode(DogColorExtractionDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func analyzeDogImage(imageData: Data, topK: Int = 3, removeBackground: Bool = true) async throws -> DogImageAnalysisResponseDTO {
        let queryItems = [
            URLQueryItem(name: "top_k", value: "\(topK)"),
            URLQueryItem(name: "remove_background", value: removeBackground ? "true" : "false")
        ]
        let data = try await uploadDogAnalysisImage(path: "/analyze/image", imageData: imageData, queryItems: queryItems)
        do {
            return try decoder.decode(DogImageAnalysisResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchUserDogs(userSeq: Int) async throws -> [DogProfile] {
        let data = try await send(path: "/users/\(userSeq)/dogs", method: "GET")
        do {
            if let raw = try? decoder.decode([DogDTO].self, from: data) {
                return raw.map { $0.toModel() }
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            return wrapped.values.map { $0.toModel() }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func createUserDog(userSeq: Int, request: CreateDogRequest) async throws -> DogProfile {
        let data = try await send(path: "/users/\(userSeq)/dogs", method: "POST", body: request)
        do {
            if let value = try? decoder.decode(DogDTO.self, from: data) {
                return value.toModel()
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<DogDTO>.self, from: data),
               let value = wrapped.value {
                return value.toModel()
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first.toModel()
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    func updateUserDog(userSeq: Int, dogSeq: Int, request: CreateDogRequest) async throws -> DogProfile {
        let data = try await send(path: "/users/\(userSeq)/dogs/\(dogSeq)", method: "PATCH", body: request)
        do {
            if let value = try? decoder.decode(DogDTO.self, from: data) {
                return value.toModel()
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<DogDTO>.self, from: data),
               let value = wrapped.value {
                return value.toModel()
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first.toModel()
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    func deleteUserDog(userSeq: Int, dogSeq: Int) async throws {
        _ = try await send(path: "/users/\(userSeq)/dogs/\(dogSeq)", method: "DELETE")
    }
}
