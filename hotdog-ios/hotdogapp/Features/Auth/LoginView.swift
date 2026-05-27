import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var userID = ""
    @State private var password = ""

    private let keyOrange = Color(red: 0.95, green: 0.55, blue: 0.26)
    private let deepOrange = Color(red: 0.88, green: 0.42, blue: 0.18)
    private let warmBackground = Color(red: 0.99, green: 0.95, blue: 0.91)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [warmBackground, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    VStack(spacing: 10) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [keyOrange, deepOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        Text("HOTDOG")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(Color(red: 0.33, green: 0.17, blue: 0.07))
                        Text("로그인하고 반려생활을 시작하세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        TextField("이메일", text: $userID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        SecureField("비밀번호", text: $password)
                            .textContentType(.password)
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }


                    Button {
                        Task {
                            _ = await appState.login(userID: userID, password: password)
                        }
                    } label: {
                        Group {
                            if appState.isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Text("로그인")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [keyOrange, deepOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isAuthenticating)

                    HStack(spacing: 10) {
                        NavigationLink {
                            AccountRecoveryView()
                        } label: {
                            secondaryActionLabel(title: "계정 찾기", systemImage: "person.crop.circle.badge.questionmark")
                        }

                        NavigationLink {
                            SignUpView()
                        } label: {
                            secondaryActionLabel(title: "회원가입", systemImage: "person.badge.plus")
                        }
                    }

                    Spacer()
                }
                .padding(20)
                .background(
                    Color.white.opacity(0.72),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
            }
            .navigationBarHidden(true)
        }
        .tint(keyOrange)
    }

    private func secondaryActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.41, green: 0.23, blue: 0.13))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                keyOrange.opacity(0.10),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(keyOrange.opacity(0.28), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
