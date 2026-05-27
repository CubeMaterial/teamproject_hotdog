import SwiftUI

struct SessionLockView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pinInput = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var resetAccountPassword = ""
    @State private var resetNewPin = ""
    @State private var resetConfirmPin = ""
    @State private var isSavingPin = false
    @State private var isResettingQuickPin = false
    @State private var showsQuickPinReset = false

    private let keyOrange = Color(red: 0.95, green: 0.55, blue: 0.26)
    private let deepOrange = Color(red: 0.88, green: 0.42, blue: 0.18)
    private let inkBrown = Color(red: 0.33, green: 0.17, blue: 0.07)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.99, green: 0.95, blue: 0.91), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: headerIconName)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(keyOrange)

                VStack(spacing: 8) {
                    Text(headerTitle)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(inkBrown)

                    Text(headerSubtitle)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if appState.shouldRequireQuickPinSetup {
                    setupForm
                } else if showsQuickPinReset {
                    resetForm
                } else {
                    unlockForm
                }


                Button {
                    appState.logout()
                } label: {
                    secondaryButtonLabel(title: "다른 계정으로 로그인", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 420)
            .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 20, y: 12)
            .padding(.horizontal, 18)
        }
    }

    private var unlockForm: some View {
        VStack(spacing: 14) {
            SecureField("간편 비밀번호 4자리", text: $pinInput)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: pinInput) { _, newValue in
                    pinInput = String(newValue.filter(\.isNumber).prefix(4))
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                _ = appState.unlockWithQuickPin(pinInput)
            } label: {
                primaryButtonLabel(title: "잠금 해제", systemImage: "lock.open.fill", isLoading: false)
            }
            .buttonStyle(.plain)
            .disabled(pinInput.count != 4)

            HStack(spacing: 10) {
                Button {
                    Task {
                        _ = await appState.loginWithBiometrics()
                    }
                } label: {
                    secondaryButtonLabel(title: appState.biometricLoginTitle, systemImage: biometricIconName)
                }
                .buttonStyle(.plain)

                Button {
                    clearResetFields()
                    appState.authErrorMessage = nil
                    showsQuickPinReset = true
                } label: {
                    secondaryButtonLabel(title: "PIN 찾기", systemImage: "key.viewfinder")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var setupForm: some View {
        VStack(spacing: 12) {
            SecureField("간편 비밀번호 4자리", text: $newPin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: newPin) { _, newValue in
                    newPin = String(newValue.filter(\.isNumber).prefix(4))
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("간편 비밀번호 확인", text: $confirmPin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: confirmPin) { _, newValue in
                    confirmPin = String(newValue.filter(\.isNumber).prefix(4))
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                Task {
                    await registerPin()
                }
            } label: {
                primaryButtonLabel(title: "PIN 등록", systemImage: "key.fill", isLoading: isSavingPin)
            }
            .buttonStyle(.plain)
            .disabled(newPin.count != 4 || confirmPin.count != 4 || isSavingPin)
        }
    }

    private var resetForm: some View {
        VStack(spacing: 12) {
            SecureField("계정 비밀번호", text: $resetAccountPassword)
                .textContentType(.password)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("새 간편 비밀번호 4자리", text: $resetNewPin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: resetNewPin) { _, newValue in
                    resetNewPin = String(newValue.filter(\.isNumber).prefix(4))
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("새 간편 비밀번호 확인", text: $resetConfirmPin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: resetConfirmPin) { _, newValue in
                    resetConfirmPin = String(newValue.filter(\.isNumber).prefix(4))
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                Task {
                    await resetQuickPin()
                }
            } label: {
                primaryButtonLabel(title: "PIN 재설정", systemImage: "arrow.triangle.2.circlepath.key", isLoading: isResettingQuickPin)
            }
            .buttonStyle(.plain)
            .disabled(resetAccountPassword.isEmpty || resetNewPin.count != 4 || resetConfirmPin.count != 4 || isResettingQuickPin)

            Button {
                clearResetFields()
                appState.authErrorMessage = nil
                showsQuickPinReset = false
            } label: {
                secondaryButtonLabel(title: "취소", systemImage: "xmark.circle")
            }
            .buttonStyle(.plain)
        }
    }

    private var headerIconName: String {
        if appState.shouldRequireQuickPinSetup { return "key.fill" }
        if showsQuickPinReset { return "key.viewfinder" }
        return "lock.shield.fill"
    }

    private var headerTitle: String {
        if appState.shouldRequireQuickPinSetup { return "간편 비밀번호 등록" }
        if showsQuickPinReset { return "간편 비밀번호 찾기" }
        return "간편 로그인"
    }

    private var headerSubtitle: String {
        if appState.shouldRequireQuickPinSetup {
            return "처음 한 번만 4자리 숫자를 등록합니다."
        }
        if showsQuickPinReset {
            return "계정 비밀번호 확인 후 새 4자리 숫자로 재설정합니다."
        }
        return "등록된 4자리 숫자로 잠금을 해제하세요."
    }

    private var primaryButtonBackground: LinearGradient {
        LinearGradient(colors: [keyOrange, deepOrange], startPoint: .leading, endPoint: .trailing)
    }

    private var biometricIconName: String {
        let title = appState.biometricLoginTitle
        if title.contains("Face ID") { return "faceid" }
        if title.contains("지문") { return "touchid" }
        return "person.crop.circle.badge.checkmark"
    }

    private func primaryButtonLabel(title: String, systemImage: String, isLoading: Bool) -> some View {
        Group {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(primaryButtonBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func secondaryButtonLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(deepOrange)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(keyOrange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(keyOrange.opacity(0.28), lineWidth: 1)
            )
    }

    private func registerPin() async {
        guard newPin == confirmPin else {
            appState.authErrorMessage = "확인 비밀번호가 일치하지 않습니다."
            return
        }

        isSavingPin = true
        defer { isSavingPin = false }
        if await appState.setQuickPin(newPin) {
            pinInput = ""
            newPin = ""
            confirmPin = ""
        }
    }

    private func resetQuickPin() async {
        guard resetNewPin == resetConfirmPin else {
            appState.authErrorMessage = "확인 비밀번호가 일치하지 않습니다."
            return
        }

        isResettingQuickPin = true
        defer { isResettingQuickPin = false }
        if await appState.resetQuickPin(accountPassword: resetAccountPassword, newPin: resetNewPin) {
            pinInput = ""
            clearResetFields()
            showsQuickPinReset = false
        }
    }

    private func clearResetFields() {
        resetAccountPassword = ""
        resetNewPin = ""
        resetConfirmPin = ""
    }
}

#Preview {
    SessionLockView()
        .environmentObject(AppState())
}
