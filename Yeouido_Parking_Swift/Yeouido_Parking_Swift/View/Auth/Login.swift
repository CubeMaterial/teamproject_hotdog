import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var globalState: GlobalState

    @State private var email = ""
    @State private var password = ""
    @State private var notice = ""
    @State private var showSignupPrompt = false
    @State private var showSignupPage = false
    @State private var signupViewVersion = 0
    @State private var isSubmitting = false
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.70, blue: 0.98),
                        Color(red: 0.56, green: 0.86, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer(minLength: 56)

                        VStack(spacing: 20) {
                            ParkingHeaderArtwork()

                            VStack(spacing: 10) {
                                Text("로그인")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundStyle(Color(red: 0.19, green: 0.28, blue: 0.39))

                                Text("여한이 없을까? 계정으로 접속해 주세요")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(red: 0.35, green: 0.41, blue: 0.50))
                            }

                            VStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("이메일")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.54))

                                    TextField("example@email.com", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .padding(.horizontal, 16)
                                        .frame(height: 54)
                                        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("비밀번호")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.54))

                                    HStack(spacing: 10) {
                                        Group {
                                            if isPasswordVisible {
                                                TextField("비밀번호 입력", text: $password)
                                            } else {
                                                SecureField("비밀번호 입력", text: $password)
                                            }
                                        }

                                        Button {
                                            isPasswordVisible.toggle()
                                        } label: {
                                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Color(red: 0.49, green: 0.55, blue: 0.64))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 54)
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.99))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                }

                                Text("비밀번호는 8자 이상으로 입력해 주세요.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if !notice.isEmpty {
                                Text(notice)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                Task {
                                    await login()
                                }
                            } label: {
                                Text(isSubmitting ? "로그인 중..." : "로그인")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.20, green: 0.53, blue: 0.96),
                                                Color(red: 0.15, green: 0.47, blue: 0.90)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: Color.blue.opacity(0.25), radius: 8, y: 4)
                            }
                            .disabled(isSubmitting)

                            VStack(spacing: 14) {
                                Divider()

                                HStack(spacing: 0) {
                                    Button("회원가입") {
                                        openSignup()
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(Color(red: 0.34, green: 0.39, blue: 0.47))

                                    Button("아이디 찾기 / 비밀번호 찾기") {
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundStyle(Color(red: 0.34, green: 0.39, blue: 0.47))
                                }
                                .font(.footnote)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                        .frame(maxWidth: 380)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color.black.opacity(0.10), radius: 24, y: 14)
                        .padding(.horizontal, 24)

                        Spacer(minLength: 56)
                    }
                    .frame(maxWidth: .infinity)
                }

                if showSignupPrompt {
                    Color.black.opacity(0.24)
                        .ignoresSafeArea()

                    signupPrompt
                        .padding(24)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showSignupPrompt)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("뒤로")
                        }
                    }
                    .foregroundStyle(Color(red: 0.19, green: 0.28, blue: 0.39))
                }
            }
            .navigationDestination(isPresented: $showSignupPage) {
                SignupView()
                    .id(signupViewVersion)
                    .environmentObject(globalState)
            }
        }
    }

    private var signupPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("존재하지 않는 회원입니다. 회원 가입 하시겠습니까?")
                .font(.headline)

            HStack(spacing: 12) {
                Button("네") {
                    openSignup()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("아니요") {
                    showSignupPrompt = false
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func openSignup() {
        showSignupPrompt = false
        email = ""
        password = ""
        notice = ""
        signupViewVersion += 1
        showSignupPage = true
    }

    @MainActor
    private func login() async {
        let normalized = normalizedEmail(email)

        guard isValidEmail(normalized) else {
            notice = "이메일 형식을 확인해 주세요."
            return
        }

        guard !password.isEmpty else {
            notice = "비밀번호를 입력해 주세요."
            return
        }

        guard password.count >= 8 else {
            notice = "비밀번호는 8자 이상 입력해 주세요."
            return
        }

        isSubmitting = true
        notice = ""

        do {
            let response = try await AuthAPI.login(email: normalized, password: password)
            globalState.login(
                email: response.userEmail,
                name: response.userName,
                phone: response.userPhone,
                date: response.userDate,
                userId: response.userID
            )
        } catch AuthAPIError.notRegistered {
            showSignupPrompt = true
        } catch {
            notice = error.localizedDescription
        }

        isSubmitting = false
    }
}

private struct ParkingHeaderArtwork: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 176, maxHeight: 112)
            .frame(maxWidth: .infinity)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(GlobalState())
    }
}
