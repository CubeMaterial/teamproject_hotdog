import Combine
import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var emailLocalPart = ""
    @State private var selectedDomain = "gmail.com"
    @State private var customDomain = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userName = ""
    @State private var phonePrefix = "010"
    @State private var phoneMiddle = ""
    @State private var phoneLast = ""
    @State private var verificationCode = ""

    @State private var checkedEmail: String?
    @State private var isEmailAvailable = false
    @State private var isCheckingEmail = false
    @State private var isCodeRequested = false
    @State private var isEmailVerified = false
    @State private var isSendingCode = false
    @State private var isVerifyingCode = false
    @State private var resendCooldown = 0
    @State private var localMessage: String?
    @State private var emailFeedbackMessage: String?
    @State private var emailFeedbackIsError = false
    @State private var verificationFeedbackMessage: String?
    @State private var verificationFeedbackIsError = false
    @State private var snackbarMessage: String?
    @State private var snackbarIsError = false
    @State private var agreedTermsOfService = false
    @State private var agreedPrivacyPolicy = false
    @State private var agreedMarketing = false

    private let keyOrange = Color(red: 0.95, green: 0.55, blue: 0.26)
    private let deepOrange = Color(red: 0.88, green: 0.42, blue: 0.18)
    private let warmBackground = Color(red: 0.99, green: 0.95, blue: 0.91)
    private let emailDomains = ["gmail.com", "naver.com", "daum.net", "kakao.com", "직접입력"]
    private let phonePrefixes = ["010"]

    private var resolvedDomain: String {
        selectedDomain == "직접입력" ? customDomain.trimmingCharacters(in: .whitespacesAndNewlines) : selectedDomain
    }

    private var fullEmail: String {
        let local = emailLocalPart.trimmingCharacters(in: .whitespacesAndNewlines)
        let domain = resolvedDomain
        guard !local.isEmpty, !domain.isEmpty else { return "" }
        return "\(local)@\(domain)"
    }

    private var resolvedPhone: String {
        guard isPhoneValid else { return "" }
        return "\(phonePrefix)-\(phoneMiddle)-\(phoneLast)"
    }

    private var isPasswordValid: Bool {
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        return password.count >= 8 && hasLetter
    }

    private var isDuplicateCheckCurrent: Bool {
        checkedEmail == fullEmail && isEmailAvailable
    }

    private var isPhoneValid: Bool {
        phonePrefix == "010" && phoneMiddle.count == 4 && phoneLast.count == 4
    }

    private var isFormValidForSignUp: Bool {
        !fullEmail.isEmpty &&
        isDuplicateCheckCurrent &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPhoneValid &&
        isPasswordValid &&
        password == confirmPassword &&
        isEmailVerified &&
        agreedTermsOfService &&
        agreedPrivacyPolicy
    }

    private var codeButtonTitle: String {
        resendCooldown > 0 ? "재요청 \(resendCooldown)s" : "인증코드 받기"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 14) {
                    emailSection
                    passwordSection
                    profileSection
                    verificationSection
                    termsSection


                    Button {
                        Task {
                            guard isDuplicateCheckCurrent else {
                                showSnackbar("아이디 중복확인을 먼저 완료해주세요.", isError: true)
                                return
                            }
                            guard isPhoneValid else {
                                showSnackbar("전화번호는 010-0000-0000 형식으로 입력해주세요.", isError: true)
                                return
                            }
                            guard password == confirmPassword else {
                                showSnackbar("비밀번호와 비밀번호 확인이 일치하지 않습니다.", isError: true)
                                return
                            }

                            let success = await appState.signUp(
                                userID: fullEmail,
                                password: password,
                                userName: userName,
                                userPhone: resolvedPhone
                            )
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if appState.isSigningUp {
                                ProgressView().tint(.white)
                            } else {
                                Text("회원가입 완료")
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
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isSigningUp || !isFormValidForSignUp)
                }
                .padding(20)
                .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }

            if let snackbarMessage {
                snackbarView(snackbarMessage, isError: snackbarIsError)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            LinearGradient(colors: [warmBackground, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .tint(keyOrange)
        .onChange(of: fullEmail) { _, _ in
            resetEmailDependentState()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: snackbarMessage)
    }

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            HStack(spacing: 6) {
                TextField("아이디", text: $emailLocalPart)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("@")
                    .foregroundStyle(.secondary)

                Picker("도메인", selection: $selectedDomain) {
                    ForEach(emailDomains, id: \.self) { domain in
                        Text(domain).tag(domain)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if selectedDomain == "직접입력" {
                TextField("도메인 직접입력 (예: company.com)", text: $customDomain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 8) {
                Text(fullEmail.isEmpty ? "이메일을 입력하세요" : fullEmail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isDuplicateCheckCurrent ? .green : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Task {
                        await checkDuplicateEmail()
                    }
                } label: {
                    if isCheckingEmail {
                        ProgressView()
                            .frame(width: 72)
                    } else {
                        Text(isDuplicateCheckCurrent ? "확인완료" : "중복확인")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 72)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isDuplicateCheckCurrent ? .green : keyOrange)
                .disabled(fullEmail.isEmpty || isCheckingEmail)
            }

            if let emailFeedbackMessage {
                inlineFeedback(emailFeedbackMessage, isError: emailFeedbackIsError)
            }
        }
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            entryField(title: "비밀번호", text: $password, secure: true)
            entryField(title: "비밀번호 확인", text: $confirmPassword, secure: true)

            Text("비밀번호는 8자 이상, 영문을 1자 이상 포함해야 합니다.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isPasswordValid || password.isEmpty ? Color.secondary : Color.red)

            if !confirmPassword.isEmpty {
                Text(password == confirmPassword ? "비밀번호가 일치합니다." : "비밀번호가 일치하지 않습니다.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(password == confirmPassword ? .green : .red)
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            entryField(title: "이름", text: $userName, secure: false)

            Text("전화번호")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            HStack(spacing: 6) {
                Picker("앞자리", selection: $phonePrefix) {
                    ForEach(phonePrefixes, id: \.self) { prefix in
                        Text(prefix).tag(prefix)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 82)
                .padding(.vertical, 12)
                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("-")
                    .foregroundStyle(.secondary)

                phoneField("0000", text: $phoneMiddle)

                Text("-")
                    .foregroundStyle(.secondary)

                phoneField("0000", text: $phoneLast)
            }

            if !phoneMiddle.isEmpty || !phoneLast.isEmpty {
                Text(isPhoneValid ? resolvedPhone : "전화번호는 010-0000-0000 형식이어야 합니다.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isPhoneValid ? .green : .red)
            }
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일 인증")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            HStack(spacing: 8) {
            Button {
                Task {
                    guard isDuplicateCheckCurrent else {
                        verificationFeedbackMessage = "아이디 중복확인을 먼저 완료해주세요."
                        verificationFeedbackIsError = true
                        showSnackbar("아이디 중복확인을 먼저 완료해주세요.", isError: true)
                        return
                    }

                        isSendingCode = true
                        defer { isSendingCode = false }
                        let result = await appState.requestEmailVerificationCode(email: fullEmail)
                        isCodeRequested = result.success
                        isEmailVerified = false
                        if result.success {
                            resendCooldown = 60
                        }
                        verificationFeedbackMessage = result.message
                        verificationFeedbackIsError = !result.success
                        showSnackbar(result.message, isError: !result.success)
                    }
                } label: {
                    if isSendingCode {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(codeButtonTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!isDuplicateCheckCurrent || isSendingCode || resendCooldown > 0)

                TextField("인증코드", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Task {
                    isVerifyingCode = true
                    defer { isVerifyingCode = false }
                    let result = await appState.verifyEmailCode(email: fullEmail, code: verificationCode)
                    isEmailVerified = result.success
                    verificationFeedbackMessage = result.message
                    verificationFeedbackIsError = !result.success
                    showSnackbar(result.message, isError: !result.success)
                }
            } label: {
                if isVerifyingCode {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(isEmailVerified ? "인증 완료" : "코드 확인")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isEmailVerified ? .green : keyOrange)
            .disabled(!isCodeRequested || verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifyingCode)

            if let verificationFeedbackMessage {
                inlineFeedback(verificationFeedbackMessage, isError: verificationFeedbackIsError)
            }
        }
    }

    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("약관 동의")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            toggleRow("[필수] HOTDOG 서비스 이용약관 동의", isOn: $agreedTermsOfService)
            Text("반려동물 용품 구매, 주문/배송, 리뷰/커뮤니티, 고객지원 기능 이용을 위한 기본 약관입니다.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            toggleRow("[필수] 개인정보 수집·이용 동의", isOn: $agreedPrivacyPolicy)
            Text("회원 식별, 주문 처리, 결제 확인, 배송 안내, 분쟁 해결을 위해 필요한 최소 정보만 수집합니다.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            toggleRow("[선택] 마케팅 정보 수신 동의", isOn: $agreedMarketing)
            Text("이벤트, 할인, 신규 서비스 소식을 앱 푸시/이메일로 받을 수 있습니다. 언제든 철회 가능합니다.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn.wrappedValue ? keyOrange : .secondary)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func entryField(title: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))

            if secure {
                SecureField("\(title) 입력", text: text)
                    .textContentType(.password)
                    .padding(13)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                TextField("\(title) 입력", text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(13)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
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

    private func messageView(_ text: String, isError: Bool) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(isError ? .red : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inlineFeedback(_ text: String, isError: Bool) -> some View {
        Label(text, systemImage: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isError ? Color.red : Color.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func snackbarView(_ text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isError ? Color.red : Color.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }

    private func resetEmailDependentState() {
        checkedEmail = nil
        isEmailAvailable = false
        isCodeRequested = false
        isEmailVerified = false
        emailFeedbackMessage = nil
        verificationFeedbackMessage = nil
        verificationCode = ""
        resendCooldown = 0
    }

    private func checkDuplicateEmail() async {
        let email = fullEmail
        guard !email.isEmpty else {
            emailFeedbackMessage = "이메일을 입력해주세요."
            emailFeedbackIsError = true
            showSnackbar("이메일을 입력해주세요.", isError: true)
            return
        }

        isCheckingEmail = true
        defer { isCheckingEmail = false }

        let result = await appState.checkUserIDAvailable(email)
        checkedEmail = email
        isEmailAvailable = result.success
        emailFeedbackMessage = result.message
        emailFeedbackIsError = !result.success
        showSnackbar(result.message, isError: !result.success)
    }

    private func showSnackbar(_ message: String, isError: Bool) {
        snackbarMessage = message
        snackbarIsError = isError

        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            await MainActor.run {
                if snackbarMessage == message {
                    snackbarMessage = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AppState())
    }
}
