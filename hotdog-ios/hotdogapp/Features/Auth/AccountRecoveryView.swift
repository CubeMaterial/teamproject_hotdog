import Combine
import SwiftUI

struct AccountRecoveryView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedMode: RecoveryMode = .findID
    @State private var userName = ""
    @State private var phoneMiddle = ""
    @State private var phoneLast = ""
    @State private var foundUserID: String?
    @State private var findIDMessage: String?
    @State private var findIDIsError = false
    @State private var isFindingID = false

    @State private var resetEmail = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var resetMessage: String?
    @State private var resetIsError = false
    @State private var isSendingCode = false
    @State private var isVerifyingCode = false
    @State private var isEmailVerified = false
    @State private var isResettingPassword = false
    @State private var resendCooldown = 0

    private let keyOrange = Color(red: 0.95, green: 0.55, blue: 0.26)
    private let deepOrange = Color(red: 0.88, green: 0.42, blue: 0.18)
    private let warmBackground = Color(red: 0.99, green: 0.95, blue: 0.91)

    private enum RecoveryMode: String, CaseIterable, Identifiable {
        case findID = "아이디 찾기"
        case resetPassword = "비밀번호 재설정"

        var id: String { rawValue }
    }

    private var resolvedPhone: String {
        guard phoneMiddle.count == 4, phoneLast.count == 4 else { return "" }
        return "010-\(phoneMiddle)-\(phoneLast)"
    }

    private var isPasswordValid: Bool {
        newPassword.count >= 8 && newPassword.range(of: "[A-Za-z]", options: .regularExpression) != nil
    }

    private var canResetPassword: Bool {
        isEmailVerified && isPasswordValid && !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private var codeButtonTitle: String {
        resendCooldown > 0 ? "재요청 \(resendCooldown)s" : "인증코드 받기"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("찾기 방식", selection: $selectedMode) {
                    ForEach(RecoveryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    switch selectedMode {
                    case .findID:
                        findIDSection
                    case .resetPassword:
                        resetPasswordSection
                    }
                }
                .padding(18)
                .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(18)
        }
        .background(
            LinearGradient(colors: [warmBackground, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle("계정 찾기")
        .navigationBarTitleDisplayMode(.inline)
        .tint(keyOrange)
        .onChange(of: resetEmail) { _, _ in
            isEmailVerified = false
            verificationCode = ""
            resetMessage = nil
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            }
        }
    }

    private var findIDSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "가입 정보 확인", systemImage: "person.text.rectangle")

            entryField(title: "이름", placeholder: "가입한 이름", text: $userName)

            VStack(alignment: .leading, spacing: 6) {
                Text("전화번호")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

                HStack(spacing: 6) {
                    Text("010")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 68)
                        .padding(.vertical, 12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("-").foregroundStyle(.secondary)
                    phoneField("0000", text: $phoneMiddle)
                    Text("-").foregroundStyle(.secondary)
                    phoneField("0000", text: $phoneLast)
                }
            }

            Button {
                Task { await findUserID() }
            } label: {
                buttonLabel(title: "아이디 찾기", isLoading: isFindingID)
            }
            .buttonStyle(.plain)
            .disabled(isFindingID || userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resolvedPhone.isEmpty)

            if let foundUserID {
                VStack(alignment: .leading, spacing: 6) {
                    Text("가입 아이디")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(foundUserID)
                        .font(.system(size: 18, weight: .bold))
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let findIDMessage {
                feedback(findIDMessage, isError: findIDIsError)
            }
        }
    }

    private var resetPasswordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "이메일 인증 후 변경", systemImage: "lock.rotation")

            entryField(title: "아이디 이메일", placeholder: "email@example.com", text: $resetEmail)
                .keyboardType(.emailAddress)

            HStack(spacing: 8) {
                Button {
                    Task { await requestResetCode() }
                } label: {
                    smallButtonLabel(title: codeButtonTitle, isLoading: isSendingCode)
                }
                .buttonStyle(.bordered)
                .disabled(isSendingCode || resendCooldown > 0 || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                TextField("인증코드", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Task { await verifyResetCode() }
            } label: {
                smallButtonLabel(title: isEmailVerified ? "인증 완료" : "코드 확인", isLoading: isVerifyingCode)
            }
            .buttonStyle(.borderedProminent)
            .tint(isEmailVerified ? .green : keyOrange)
            .disabled(isVerifyingCode || verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            SecureField("새 비밀번호", text: $newPassword)
                .textContentType(.newPassword)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            SecureField("새 비밀번호 확인", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("비밀번호는 8자 이상, 영문을 1자 이상 포함해야 합니다.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isPasswordValid || newPassword.isEmpty ? Color.secondary : Color.red)

            if !confirmPassword.isEmpty {
                Text(newPassword == confirmPassword ? "비밀번호가 일치합니다." : "비밀번호가 일치하지 않습니다.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(newPassword == confirmPassword ? .green : .red)
            }

            Button {
                Task { await resetPassword() }
            } label: {
                buttonLabel(title: "비밀번호 변경", isLoading: isResettingPassword)
            }
            .buttonStyle(.plain)
            .disabled(isResettingPassword || !canResetPassword)

            if let resetMessage {
                feedback(resetMessage, isError: resetIsError)
            }
        }
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(red: 0.33, green: 0.17, blue: 0.07))
    }

    private func entryField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func phoneField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .onChange(of: text.wrappedValue) { _, newValue in
                text.wrappedValue = String(newValue.filter(\.isNumber).prefix(4))
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func buttonLabel(title: String, isLoading: Bool) -> some View {
        Group {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [keyOrange, deepOrange], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .opacity(isLoading ? 0.85 : 1)
    }

    private func smallButtonLabel(title: String, isLoading: Bool) -> some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func feedback(_ text: String, isError: Bool) -> some View {
        Label(text, systemImage: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isError ? Color.red : Color.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func findUserID() async {
        isFindingID = true
        defer { isFindingID = false }

        let result = await appState.findUserID(userName: userName, userPhone: resolvedPhone)
        foundUserID = result.userID
        findIDMessage = result.message
        findIDIsError = !result.success
    }

    private func requestResetCode() async {
        isSendingCode = true
        defer { isSendingCode = false }

        let result = await appState.requestEmailVerificationCode(email: resetEmail)
        isEmailVerified = false
        resetMessage = result.message
        resetIsError = !result.success
        if result.success {
            resendCooldown = 60
        }
    }

    private func verifyResetCode() async {
        isVerifyingCode = true
        defer { isVerifyingCode = false }

        let result = await appState.verifyEmailCode(email: resetEmail, code: verificationCode)
        isEmailVerified = result.success
        resetMessage = result.message
        resetIsError = !result.success
    }

    private func resetPassword() async {
        guard newPassword == confirmPassword else {
            resetMessage = "비밀번호 확인이 일치하지 않습니다."
            resetIsError = true
            return
        }

        isResettingPassword = true
        defer { isResettingPassword = false }

        let result = await appState.resetPassword(userID: resetEmail, newPassword: newPassword)
        resetMessage = result.message
        resetIsError = !result.success
        if result.success {
            newPassword = ""
            confirmPassword = ""
            verificationCode = ""
            isEmailVerified = false
        }
    }
}

#Preview {
    NavigationStack {
        AccountRecoveryView()
            .environmentObject(AppState())
    }
}
