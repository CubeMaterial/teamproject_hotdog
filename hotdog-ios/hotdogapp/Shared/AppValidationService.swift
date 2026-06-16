import Foundation

struct AppValidationService {
    func isValidPassword(_ text: String) -> Bool {
        guard text.count >= 8 else { return false }
        return text.range(of: "[A-Za-z]", options: .regularExpression) != nil
    }

    func isValidEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    func validateLoginInput(userID: String, password: String) -> String? {
        let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, !password.isEmpty else {
            return "아이디와 비밀번호를 입력해주세요."
        }
        return nil
    }

    func validateSignUpInput(userID: String, password: String, userName: String) -> String? {
        let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedID) else {
            return "아이디는 이메일 형식이어야 합니다."
        }
        guard !trimmedID.isEmpty, !trimmedPassword.isEmpty, !trimmedName.isEmpty else {
            return "아이디, 비밀번호, 이름을 입력해주세요."
        }
        guard isValidPassword(trimmedPassword) else {
            return "비밀번호는 8자 이상, 영문 포함이어야 합니다."
        }
        return nil
    }
}
