import CryptoKit
import Foundation
import LocalAuthentication

struct AuthStateService {
    func quickPinHash(for pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func biometricLoginTitle() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID로 로그인"
        case .touchID:
            return "지문으로 로그인"
        default:
            return "생체인증 로그인"
        }
    }

    func canEvaluateBiometrics(context: LAContext) -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func evaluateBiometric(context: LAContext) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "빠른 로그인을 위해 생체인증을 사용합니다."
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
