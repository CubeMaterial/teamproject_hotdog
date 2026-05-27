//
//  NotificationOverlayView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI
import UIKit

struct NotificationOverlayView: View {
    @Binding var isPresented: Bool

    let notifications: [AppNotification]
    let onNotificationTap: (AppNotification) -> Void
    let onClearAll: () -> Void
    let onAppear: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    HStack {
                        Text("알림")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)

                        Spacer()

                        if !notifications.isEmpty {
                            Button("전체삭제") {
                                onClearAll()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "167A8C"))
                        }
                    }

                    if notifications.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.gray)

                            Text("알림 내용이 없습니다.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    } else {
                        ForEach(notifications) { notification in
                            Button {
                                onNotificationTap(notification)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    appIconBadge(isRead: notification.isRead)

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(notification.isRead ? "읽은 알림" : "새 알림")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(notification.isRead ? .secondary : Color(hex: "167A8C"))

                                            Spacer()

                                            Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }

                                        Text(notification.message)
                                            .font(.system(size: 15, weight: notification.isRead ? .medium : .semibold))
                                            .foregroundStyle(.black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(16)
                                .background(notification.isRead ? Color.black.opacity(0.04) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            notification.isRead ? Color.clear : Color(hex: "C6EEE6"),
                                            lineWidth: 1.2
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(
                                    color: notification.isRead ? .clear : Color(hex: "63C9F2").opacity(0.08),
                                    radius: 10,
                                    y: 6
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: min(340, geometry.size.height * 0.38), alignment: .top)
            .background(
                Color.white
                    .ignoresSafeArea(edges: .top)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                onAppear()
            }
        }
    }

    private var header: some View {
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
        .frame(height: 44)
    }
}

private extension NotificationOverlayView {
    @ViewBuilder
    func appIconBadge(isRead: Bool) -> some View {
        if let iconName = appPrimaryIconName,
           let uiImage = UIImage(named: iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isRead ? Color.black.opacity(0.1) : Color(hex: "B8E9DF"), lineWidth: 1)
                )
        } else {
            ZStack {
                Circle()
                    .fill(isRead ? Color.black.opacity(0.06) : Color(hex: "DDF7F3"))
                    .frame(width: 34, height: 34)

                Image(systemName: isRead ? "bell" : "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isRead ? .secondary : Color(hex: "167A8C"))
            }
        }
    }

    var appPrimaryIconName: String? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let iconName = files.last
        else {
            return nil
        }
        return iconName
    }
}

#Preview {
    NotificationOverlayView(
        isPresented: .constant(true),
        notifications: [],
        onNotificationTap: { _ in },
        onClearAll: {},
        onAppear: {}
    )
}
