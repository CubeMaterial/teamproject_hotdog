import SwiftUI

enum DogColorTheme: String, CaseIterable, Identifiable {
    case black
    case gray
    case white
    case brown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black:
            return "블랙"
        case .gray:
            return "그레이"
        case .white:
            return "화이트"
        case .brown:
            return "브라운"
        }
    }

    var palette: AppPalette {
        switch self {
        case .black:
            return AppPalette(
                primary: Color(red: 0.01, green: 0.01, blue: 0.015),
                secondary: Color(red: 0.16, green: 0.15, blue: 0.14),
                accent: Color(red: 0.98, green: 0.70, blue: 0.22),
                background: Color(red: 0.90, green: 0.89, blue: 0.86),
                cardBackground: Color.white,
                textPrimary: Color(red: 0.03, green: 0.025, blue: 0.02),
                textSecondary: Color(red: 0.27, green: 0.25, blue: 0.23)
            )
        case .gray:
            return AppPalette(
                primary: Color(red: 0.42, green: 0.47, blue: 0.54),
                secondary: Color(red: 0.70, green: 0.74, blue: 0.80),
                accent: Color(red: 0.20, green: 0.50, blue: 0.78),
                background: Color(red: 0.96, green: 0.97, blue: 0.98),
                cardBackground: Color.white,
                textPrimary: Color(red: 0.10, green: 0.13, blue: 0.16),
                textSecondary: Color(red: 0.39, green: 0.43, blue: 0.48)
            )
        case .white:
            return AppPalette(
                primary: Color(red: 0.42, green: 0.35, blue: 0.27),
                secondary: Color(red: 0.72, green: 0.63, blue: 0.52),
                accent: Color(red: 0.92, green: 0.52, blue: 0.20),
                background: Color(red: 0.99, green: 0.98, blue: 0.95),
                cardBackground: Color.white,
                textPrimary: Color(red: 0.16, green: 0.12, blue: 0.08),
                textSecondary: Color(red: 0.43, green: 0.36, blue: 0.29)
            )
        case .brown:
            return AppPalette(
                primary: Color(red: 0.36, green: 0.18, blue: 0.08),
                secondary: Color(red: 0.66, green: 0.39, blue: 0.18),
                accent: Color(red: 0.94, green: 0.48, blue: 0.18),
                background: Color(red: 0.98, green: 0.93, blue: 0.87),
                cardBackground: Color.white,
                textPrimary: Color(red: 0.17, green: 0.08, blue: 0.03),
                textSecondary: Color(red: 0.42, green: 0.25, blue: 0.15)
            )
        }
    }
}

struct AppPalette {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
}
