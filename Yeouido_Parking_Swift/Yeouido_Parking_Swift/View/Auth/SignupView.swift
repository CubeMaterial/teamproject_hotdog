import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var password: String
    @State private var confirmPassword: String
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var sentVerificationCode = ""
    @State private var notice = ""
    @State private var isSubmitting = false
    @State private var showSignupCompleteAlert = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    init(prefilledEmail: String = "", prefilledPassword: String = "") {
        _email = State(initialValue: prefilledEmail)
        _password = State(initialValue: prefilledPassword)
        _confirmPassword = State(initialValue: "")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#63C9F2"),
                    Color(hex: "#75B992")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer(minLength: 32)

                    VStack(spacing: 0) {
                        Text("CREATE ACCOUNT")
                            .font(.system(size: 12, weight: .bold))
                            .kerning(1.2)
                            .foregroundStyle(Color(hex: "#167A8C"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#EAF7FA"))
                            .clipShape(Capsule())

                        Text("회원가입")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))
                            .padding(.top, 10)

                        Text("계정을 만들고 서비스를 이용해 보세요")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding(.top, 10)

                        VStack(spacing: 14) {
                            SignupInputField(
                                placeholder: "이름",
                                text: $name
                            )

                            SignupInputField(
                                placeholder: "이메일",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            SignupInputField(
                                placeholder: "전화번호",
                                text: phoneNumberDisplayBinding,
                                keyboardType: .phonePad
                            )
                            .textContentType(.telephoneNumber)

                            SignupSecureInputField(
                                placeholder: "비밀번호",
                                text: $password,
                                isVisible: $isPasswordVisible,
                                fieldID: "signup-password"
                            )

                            SignupSecureInputField(
                                placeholder: "비밀번호 확인",
                                text: $confirmPassword,
                                isVisible: $isConfirmPasswordVisible,
                                fieldID: "signup-confirm-password"
                            )

                            Text("비밀번호는 8자 이상, 영문과 숫자를 모두 포함해야 합니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 10) {
                                SignupInputField(
                                    placeholder: "인증 코드",
                                    text: $verificationCode,
                                    keyboardType: .numberPad
                                )

                                Button("인증 요청") {
                                    sendVerificationCode()
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 104, height: 58)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }
                        .padding(.top, 32)

                        if !notice.isEmpty {
                            Text(notice)
                                .font(.footnote)
                                .foregroundStyle(noticeColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 14)
                        }

                        Button {
                            Task {
                                await signup()
                            }
                        } label: {
                            Text(isSubmitting ? "회원가입 중..." : "회원가입 완료")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.95),
                                            Color.blue.opacity(0.85)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                        }
                        .disabled(isSubmitting)
                        .padding(.top, 24)

                        Divider()
                            .padding(.top, 28)

                        HStack(spacing: 6) {
                            Text("이미 계정이 있으신가요?")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))

                            Button("로그인") {
                                dismiss()
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 22)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 30)
                    .frame(maxWidth: 390)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: 14)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("회원가입 완료", isPresented: $showSignupCompleteAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("회원가입이 완료되었습니다.")
        }
    }

    private var noticeColor: Color {
        notice.contains("전송") ? .secondary : .red
    }

    private var phoneNumberDisplayBinding: Binding<String> {
        Binding(
            get: {
                formatPhoneNumberForDisplay(phoneNumber)
            },
            set: { newValue in
                let digitsOnly = String(newValue.filter(\.isNumber).prefix(11))
                phoneNumber = digitsOnly
            }
        )
    }

    private func formatPhoneNumberForDisplay(_ value: String) -> String {
        let digits = String(value.filter(\.isNumber).prefix(11))
        guard !digits.isEmpty else { return "" }

        if digits.count <= 3 {
            return digits
        }
        if digits.count <= 7 {
            let first = digits.prefix(3)
            let second = digits.dropFirst(3)
            return "\(first)-\(second)"
        }
        let first = digits.prefix(3)
        let second = digits.dropFirst(3).prefix(4)
        let third = digits.dropFirst(7)
        return "\(first)-\(second)-\(third)"
    }

    private func sendVerificationCode() {
        let normalized = normalizedEmail(email)
        let normalizedPhone = normalizedPhoneNumber(phoneNumber)

        guard isValidEmail(normalized) else {
            notice = "이메일 형식을 확인해 주세요."
            return
        }

        guard isValidPhoneNumber(normalizedPhone) else {
            notice = "전화번호 형식을 확인해 주세요. (예: 01012345678)"
            return
        }

        guard isValidSignupPassword(password) else {
            notice = "비밀번호는 8자 이상이며 영문과 숫자를 모두 포함해야 합니다."
            return
        }

        guard password == confirmPassword else {
            notice = "비밀번호가 일치하지 않습니다."
            return
        }

        email = normalized
        phoneNumber = normalizedPhone
        sentVerificationCode = String(format: "%06d", Int.random(in: 0...999999))
        notice = "\(normalized)로 인증 코드를 전송했습니다. 개발용 코드: \(sentVerificationCode)"
    }

    @MainActor
    private func signup() async {
        let normalized = normalizedEmail(email)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = normalizedPhoneNumber(phoneNumber)

        guard isValidEmail(normalized) else {
            notice = "이메일 형식을 확인해 주세요."
            return
        }

        guard isValidPhoneNumber(normalizedPhone) else {
            notice = "전화번호 형식을 확인해 주세요. (예: 01012345678)"
            return
        }

        guard isValidSignupPassword(password) else {
            notice = "비밀번호는 8자 이상이며 영문과 숫자를 모두 포함해야 합니다."
            return
        }

        guard password == confirmPassword else {
            notice = "비밀번호가 일치하지 않습니다."
            return
        }

        guard !sentVerificationCode.isEmpty else {
            notice = "먼저 인증 요청을 진행해 주세요."
            return
        }

        guard verificationCode == sentVerificationCode else {
            notice = "인증 코드가 일치하지 않습니다."
            return
        }

        isSubmitting = true
        notice = ""

        do {
            _ = try await AuthAPI.signup(
                email: normalized,
                password: password,
                name: trimmedName,
                phoneNumber: normalizedPhone
            )
            showSignupCompleteAlert = true
        } catch {
            notice = error.localizedDescription
        }

        isSubmitting = false
    }
}

private struct SignupInputField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color(hex: "#1F2937"))
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(Color(hex: "#F6F8FA"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.03), lineWidth: 1)
            )
    }
}

private struct SignupSecureInputField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    let fieldID: String

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .id(fieldID)
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color(hex: "#1F2937"))

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#7A8699"))
            }
        }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(Color(hex: "#F6F8FA"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.03), lineWidth: 1)
            )
    }
}

#Preview {
    SignupView()
        .environmentObject(GlobalState())
}
