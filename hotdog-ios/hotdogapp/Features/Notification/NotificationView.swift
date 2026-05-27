import SwiftUI

struct NotificationView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection(palette: palette)
                    notificationSummaryCard(palette: palette)
                    notificationListSection(palette: palette)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
        }
    }

    private func headerSection(palette: AppPalette) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("알림")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text("\(appState.currentUserDisplayName)님을 위한 쿠폰, 배송, 이벤트 소식")
                    .font(.system(size: 14))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            Button("전체 읽음") {
                appState.markAllNotificationsRead()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(palette.primary)
        }
    }

    private func notificationSummaryCard(palette: AppPalette) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.accent.opacity(0.14))
                    .frame(width: 60, height: 60)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(palette.accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("새 알림 \(appState.notifications.filter(\.isNew).count)개")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text("배송 상태와 추천 상품 알림을 빠르게 확인하세요")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func notificationListSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("전체 알림")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(palette.textPrimary)

            ForEach(appState.notifications) { item in
                Button {
                    appState.markNotificationRead(item)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(item.isNew ? palette.accent : palette.secondary.opacity(0.35))
                            .frame(width: 10, height: 10)
                            .padding(.top, 7)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(palette.primary)
                                if item.isNew {
                                    Text("NEW")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(palette.accent, in: Capsule())
                                }
                            }

                            Text(item.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                            Text(item.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
