import SwiftUI
import UIKit

struct AppRouterView: View {
    @EnvironmentObject private var appState: AppState

    private var route: AppRoute {
        if !appState.isLoggedIn { return .auth }
        if appState.isSessionLocked { return .sessionLock }
        if appState.needsDogOnboarding { return .dogOnboarding }
        return .main
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch route {
            case .auth:
                LoginView()
            case .sessionLock:
                SessionLockView()
            case .dogOnboarding:
                DogOnboardingView()
            case .main:
                MainShellView()
            }

            if let snackbarMessage = appState.snackbarMessage {
                snackbarView(snackbarMessage, isError: appState.snackbarIsError)
                    .padding(.horizontal, 16)
                    .padding(.bottom, route == .main ? 92 : 22)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.22), value: snackbarMessage)
            }
        }
    }

    private func snackbarView(_ message: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(isError ? Color.red : appState.palette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
        .frame(maxWidth: .infinity)
    }
}

private struct MainShellView: View {
    @EnvironmentObject private var appState: AppState
    @State private var floatingButtonOffset: CGSize = .zero
    @GestureState private var floatingDragOffset: CGSize = .zero
    @State private var didDragFloatingButton = false

    private var selectedProductNavigationBinding: Binding<Bool> {
        Binding(
            get: { appState.selectedProduct != nil },
            set: { isPresented in
                if !isPresented {
                    appState.selectedProduct = nil
                }
            }
        )
    }

    private var selectedReviewNavigationBinding: Binding<Bool> {
        Binding(
            get: { appState.selectedReview != nil },
            set: { isPresented in
                if !isPresented {
                    appState.selectedReview = nil
                }
            }
        )
    }

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $appState.selectedTab) {
                    HomeView()
                        .tabItem {
                            Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
                        }
                        .tag(AppTab.home)

                    ProductListView()
                        .tabItem {
                            Label(AppTab.products.title, systemImage: AppTab.products.systemImage)
                        }
                        .tag(AppTab.products)

                    WalkView()
                        .tabItem {
                            Label(AppTab.walk.title, systemImage: AppTab.walk.systemImage)
                        }
                        .tag(AppTab.walk)

                    NotificationView()
                        .tabItem {
                            Label(AppTab.notifications.title, systemImage: AppTab.notifications.systemImage)
                        }
                        .tag(AppTab.notifications)

                    MyPageView()
                        .tabItem {
                            Label(AppTab.myPage.title, systemImage: AppTab.myPage.systemImage)
                        }
                        .tag(AppTab.myPage)
                }
                .tint(palette.accent)

                Button {
                    if didDragFloatingButton {
                        didDragFloatingButton = false
                        return
                    }
                    appState.showChatbot = true
                } label: {
                    ChatbotAssetFloatingButton()
                        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                }
                .buttonStyle(.plain)
                .frame(width: 72, height: 72)
                .contentShape(Rectangle())
                .padding(.trailing, 20)
                .padding(.bottom, 92)
                .zIndex(10)
                .offset(
                    x: floatingButtonOffset.width + floatingDragOffset.width,
                    y: floatingButtonOffset.height + floatingDragOffset.height
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .updating($floatingDragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            let dragDistance = hypot(value.translation.width, value.translation.height)
                            if dragDistance > 6 {
                                didDragFloatingButton = true
                            }
                            floatingButtonOffset.width += value.translation.width
                            floatingButtonOffset.height += value.translation.height
                        }
                )
            }
            .navigationDestination(isPresented: $appState.showCart) {
                appState.cartSheetView()
            }
            .navigationDestination(isPresented: $appState.showPayment) {
                appState.paymentSheetView()
            }
            .navigationDestination(isPresented: $appState.showFavoriteList) {
                appState.favoriteListSheetView()
            }
            .navigationDestination(isPresented: $appState.showPurchaseHistory) {
                appState.purchaseHistorySheetView()
            }
            .navigationDestination(isPresented: $appState.showReviewList) {
                appState.reviewListSheetView()
            }
            .navigationDestination(isPresented: $appState.showReviewComposer) {
                appState.reviewComposerSheetView()
            }
            .navigationDestination(isPresented: selectedProductNavigationBinding) {
                if let product = appState.selectedProduct {
                    appState.productDetailSheet(for: product)
                }
            }
            .navigationDestination(isPresented: selectedReviewNavigationBinding) {
                if let review = appState.selectedReview {
                    appState.reviewDetailSheet(for: review)
                }
            }
        }
        .sheet(isPresented: $appState.showChatbot) {
            appState.chatbotSheetView()
        }
    }
}

private struct ChatbotAssetFloatingButton: View {
    var body: some View {
        if let image = chatbotImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
        } else {
            ChatbotFloatingButton()
        }
    }

    private var chatbotImage: UIImage? {
        let names = [
            "챗봇 얼굴만",
            "챗봇 얼굴만",
            "챗봇 얼굴만".precomposedStringWithCanonicalMapping,
            "챗봇 얼굴만".decomposedStringWithCanonicalMapping
        ]

        for name in names {
            if let image = UIImage(named: name) {
                return image
            }
        }
        return nil
    }
}

#Preview {
    AppRouterView()
        .environmentObject(AppState())
}
