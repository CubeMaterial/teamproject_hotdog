//
//  MenuDrawerView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct MenuDrawerView: View {
    @EnvironmentObject private var globalState: GlobalState
    @Binding var isPresented: Bool
    @Binding var isDarkModeEnabled: Bool
    let onLoginTap: () -> Void
    let onFavoriteListTap: () -> Void
    let onReservationListTap: () -> Void
    @State private var isCustomerInfoPresented = false

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.top, 12)

                    Text("메뉴")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.black)

                    UserInfoCard(
                        isLoggedIn: globalState.userLoginStatus,
                        name: globalState.currentUserName,
                        email: globalState.currentUserEmail
                    )

                    VStack(spacing: 14) {
                        DrawerMenuButton(
                            title: "고객정보",
                            systemName: "person.text.rectangle"
                        ) {
                            isCustomerInfoPresented = true
                        }
                        DrawerMenuButton(
                            title: "즐겨찾기",
                            systemName: "heart.text.square"
                        ) {
                            onFavoriteListTap()

                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isPresented = false
                            }
                        }
                        DrawerMenuButton(
                            title: "예약내역",
                            systemName: "calendar.badge.clock"
                        ) {
                            if globalState.userLoginStatus {
                                onReservationListTap()
                            } else {
                                onLoginTap()
                            }

                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isPresented = false
                            }
                        }

                        HStack(spacing: 14) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "2F4858"))
                                .frame(width: 22)

                            Text("다크모드 설정")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)

                            Spacer()

                            Toggle("", isOn: $isDarkModeEnabled)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    Spacer(minLength: 28)

                    Group {
                        if globalState.userLoginStatus {
                            Button {
                                globalState.logout()
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    isPresented = false
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                        .frame(width: 22)

                                    Text("로그아웃")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "F06D6D"),
                                            Color(hex: "DC4D63")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color(hex: "DC4D63").opacity(0.22), radius: 12, y: 8)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                onLoginTap()
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    isPresented = false
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "person.badge.key.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                        .frame(width: 22)

                                    Text("로그인 하기")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "4E9CF9"),
                                            Color(hex: "2F7AE5")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color(hex: "2F7AE5").opacity(0.2), radius: 12, y: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 112)
                }
                .padding(.horizontal, 20)
                .frame(width: min(280, geometry.size.width * 0.74))
                .frame(maxHeight: .infinity)
                .background(Color.white.ignoresSafeArea())
                .shadow(color: .black.opacity(0.14), radius: 18, x: -8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .overlay {
                if isCustomerInfoPresented {
                    ZStack {
                        Color.black.opacity(0.18)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isCustomerInfoPresented = false
                            }

                        CustomerInfoPopupView(
                            isPresented: $isCustomerInfoPresented,
                            isLoggedIn: globalState.userLoginStatus,
                            name: globalState.currentUserName,
                            email: globalState.currentUserEmail,
                            phone: globalState.currentUserPhone,
                            signupDate: globalState.currentUserDate
                        )
                        .padding(24)
                    }
                }
            }
        }
    }
}

private struct DrawerMenuButton: View {
    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "2F4858"))
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct CustomerInfoPopupView: View {
    @Binding var isPresented: Bool
    let isLoggedIn: Bool
    let name: String
    let email: String
    let phone: String
    let signupDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("고객정보")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }
            }

            if isLoggedIn {
                InfoRow(title: "이름", value: name.isEmpty ? "-" : name)
                InfoRow(title: "이메일", value: email.isEmpty ? "-" : email)
                InfoRow(title: "전화번호", value: phone.isEmpty ? "-" : phone)
                InfoRow(title: "가입일", value: signupDate.isEmpty ? "-" : signupDate)
            } else {
                Text("로그인 후 고객정보를 확인할 수 있습니다.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black.opacity(0.64))
            }
        }
        .padding(22)
        .frame(maxWidth: 340, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black.opacity(0.52))

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
        }
    }
}

private struct UserInfoCard: View {
    let isLoggedIn: Bool
    let name: String
    let email: String

    private var displayName: String {
        if !name.isEmpty {
            return name
        }

        return isLoggedIn ? "로그인 사용자" : "로그인 필요"
    }

    private var displayEmail: String {
        if isLoggedIn, !email.isEmpty {
            return email
        }

        return "채팅문의와 예약 기능은 로그인 후 이용 가능합니다."
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isLoggedIn ? "person.crop.circle.fill" : "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 30))
                .foregroundStyle(Color(hex: "2F4858"))

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)

                Text(displayEmail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    MenuDrawerView(
        isPresented: .constant(true),
        isDarkModeEnabled: .constant(false),
        onLoginTap: {},
        onFavoriteListTap: {},
        onReservationListTap: {}
    )
    .environmentObject(GlobalState())
}
