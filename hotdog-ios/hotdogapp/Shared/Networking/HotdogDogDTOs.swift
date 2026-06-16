import Foundation

struct DogBreedPredictionDTO: Decodable {
    struct Prediction: Decodable {
        let label: String?
        let breed: String?
        let confidence: Double?
    }

    struct ImageSize: Decodable {
        let width: Int?
        let height: Int?
    }

    let breed: String?
    let label: String?
    let confidence: Double?
    let isOther: Bool?
    let otherThreshold: Double?
    let topPredictions: [Prediction]?
    let backgroundRemoved: Bool?
    let imageSize: ImageSize?
    let modelDir: String?
    let modelFile: String?
    let modelSHA256: String?
    let device: String?

    enum CodingKeys: String, CodingKey {
        case breed
        case label
        case confidence
        case isOther = "is_other"
        case otherThreshold = "other_threshold"
        case topPredictions = "top_predictions"
        case backgroundRemoved = "background_removed"
        case imageSize = "image_size"
        case modelDir = "model_dir"
        case modelFile = "model_file"
        case modelSHA256 = "model_sha256"
        case device
    }

    var resolvedBreed: String {
        let candidates = [breed, topPredictions?.first?.breed, label]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

        for candidate in candidates where !candidate.isEmpty {
            let mapped = Self.koreanBreedName(for: candidate)
            if mapped != "기타" || candidate == "기타" {
                return mapped
            }
        }
        return "기타"
    }

    private static func koreanBreedName(for prediction: String) -> String {
        switch prediction.lowercased().replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: " ", with: "_") {
        case "몰티즈", "말티즈", "maltese":
            return "몰티즈"
        case "푸들", "poodle", "toy_poodle", "miniature_poodle", "standard_poodle":
            return "푸들"
        case "믹스견", "mixed", "mixed_breed", "mix":
            return "믹스견"
        case "포메라니안", "pomeranian":
            return "포메라니안"
        case "비숑 프리제", "비숑프리제", "비숑", "bichon_frise", "bichon":
            return "비숑 프리제"
        case "치와와", "chihuahua":
            return "치와와"
        case "시츄", "시추", "shih_tzu", "shihtzu":
            return "시츄"
        case "진돗개", "진도개", "jindo", "korean_jindo", "jindo_dog":
            return "진돗개"
        case "요크셔테리어", "요크셔 테리어", "yorkshire_terrier", "yorkie":
            return "요크셔테리어"
        case "골든 리트리버", "골든리트리버", "golden_retriever":
            return "골든 리트리버"
        default:
            return "기타"
        }
    }
}

struct DogColorExtractionDTO: Decodable {
    struct ColorResult: Decodable {
        let color: String?
        let colorKO: String?
        let hex: String?
        let ratio: Double?
        let percentage: Double?
        let pixelCount: Int?

        enum CodingKeys: String, CodingKey {
            case color
            case colorKO = "color_ko"
            case hex
            case ratio
            case percentage
            case pixelCount = "pixel_count"
        }
    }

    struct ImageSize: Decodable {
        let width: Int?
        let height: Int?
    }

    let totalPixels: Int?
    let dominantColor: String?
    let dominantColorKO: String?
    let mainHex: String?
    let colors: [ColorResult]?
    let backgroundRemoved: Bool?
    let imageSize: ImageSize?

    enum CodingKeys: String, CodingKey {
        case totalPixels = "total_pixels"
        case dominantColor = "dominant_color"
        case dominantColorKO = "dominant_color_ko"
        case mainHex = "main_hex"
        case colors
        case backgroundRemoved = "background_removed"
        case imageSize = "image_size"
    }

    var resolvedTheme: DogColorTheme {
        let candidates = [dominantColorKO, dominantColor]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

        for candidate in candidates {
            if let theme = Self.theme(for: candidate) {
                return theme
            }
        }
        return .brown
    }

    private static func theme(for colorName: String) -> DogColorTheme? {
        let value = colorName.lowercased()
        if value.contains("블랙") || value.contains("검정") || value.contains("black") {
            return .black
        }
        if value.contains("그레이") || value.contains("회색") || value.contains("gray") || value.contains("grey") {
            return .gray
        }
        if value.contains("화이트") || value.contains("흰") || value.contains("white") {
            return .white
        }
        if value.contains("브라운") || value.contains("갈색") || value.contains("brown") {
            return .brown
        }
        return nil
    }
}

struct DogImageAnalysisResponseDTO: Decodable {
    let breed: DogBreedPredictionDTO
    let color: DogColorExtractionDTO

    var resolvedBreed: String {
        breed.resolvedBreed
    }

    var resolvedTheme: DogColorTheme {
        color.resolvedTheme
    }
}

struct DogDTO: Decodable {
    let dogSeq: Int?
    let dogName: String?
    let breedName: String?
    let ageName: String?
    let weightText: String?
    let colorName: String?
    let dogImage: String?

    enum CodingKeys: String, CodingKey {
        case dogSeq = "dog_seq"
        case dogName = "dog_name"
        case breedName = "breed_name"
        case ageName = "age_name"
        case weightText = "weight_text"
        case colorName = "color_name"
        case dogImage = "dog_image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dogSeq = try container.decodeLossyIntIfPresent(forKey: .dogSeq)
        dogName = try container.decodeLossyStringIfPresent(forKey: .dogName)
        breedName = try container.decodeLossyStringIfPresent(forKey: .breedName)
        ageName = try container.decodeLossyStringIfPresent(forKey: .ageName)
        weightText = try container.decodeLossyStringIfPresent(forKey: .weightText)
        colorName = try container.decodeLossyStringIfPresent(forKey: .colorName)
        dogImage = try container.decodeLossyStringIfPresent(forKey: .dogImage)
    }

    func toModel() -> DogProfile {
        DogProfile(
            dbSeq: dogSeq,
            name: (dogName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? dogName! : "반려견",
            breed: (breedName?.isEmpty == false) ? breedName! : "견종 미상",
            age: (ageName?.isEmpty == false) ? ageName! : "나이 미상",
            weight: (weightText?.isEmpty == false) ? weightText! : "체중 미상",
            theme: resolvedTheme(from: colorName),
            imageURL: normalizedDogImageURL(dogImage)
        )
    }

    private func normalizedDogImageURL(_ raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if URL(string: value)?.scheme != nil {
            return value
        }
        return APIConfiguration.absoluteURLString(path: value.hasPrefix("/") ? value : "/\(value)")
    }

    private func resolvedTheme(from raw: String?) -> DogColorTheme {
        let value = (raw ?? "").lowercased()
        if value.contains("black") || value.contains("검정") || value.contains("블랙") { return .black }
        if value.contains("gray") || value.contains("grey") || value.contains("회색") || value.contains("그레이") { return .gray }
        if value.contains("white") || value.contains("흰") || value.contains("화이트") { return .white }
        return .brown
    }
}

struct CreateDogRequest: Encodable {
    let dogName: String
    let breedName: String
    let ageName: String
    let weightText: String
    let colorName: String
    let dogImage: String?

    enum CodingKeys: String, CodingKey {
        case dogName = "dog_name"
        case breedName = "breed_name"
        case ageName = "age_name"
        case weightText = "weight_text"
        case colorName = "color_name"
        case dogImage = "dog_image"
    }
}
