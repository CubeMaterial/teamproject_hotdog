import SwiftUI

struct ReviewListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var reviewPendingDeletion: HotdogReview?
    @State private var showReviewablePurchasePicker = false

    private var mode: ReviewListMode {
        appState.reviewListMode
    }

    private var displayedReviews: [HotdogReview] {
        switch mode {
        case .all:
            return appState.sortedReviews
        case .mine:
            return appState.myReviews
        }
    }

    var body: some View {
        let palette = appState.palette

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                headerSection(palette: palette)

                if appState.isLoadingRemoteData && displayedReviews.isEmpty {
                    ProgressView("후기를 불러오는 중...")
                        .tint(palette.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                }

                if !appState.isLoadingRemoteData && displayedReviews.isEmpty {
                    emptyState(palette: palette)
                }

                ForEach(displayedReviews) { review in
                    reviewFeedCard(review, palette: palette)
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(mode == .mine ? "내 후기 관리" : "후기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode == .all {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("작성") {
                        openReviewablePurchasePicker()
                    }
                    .foregroundStyle(palette.primary)
                }
            }
        }
        .navigationDestination(isPresented: $showReviewablePurchasePicker) {
            ReviewablePurchaseSelectionView()
        }
        .alert("후기를 삭제할까요?", isPresented: deleteConfirmationBinding) {
            Button("취소", role: .cancel) {
                reviewPendingDeletion = nil
            }
            Button("삭제", role: .destructive) {
                if let reviewPendingDeletion {
                    Task {
                        let success = await appState.deleteReview(reviewPendingDeletion)
                        if success {
                            self.reviewPendingDeletion = nil
                        }
                    }
                }
            }
        } message: {
            Text("삭제한 후기는 복구할 수 없습니다.")
        }
    }

    private func openReviewablePurchasePicker() {
        showReviewablePurchasePicker = true
        Task { await appState.loadPurchaseHistory() }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { reviewPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    reviewPendingDeletion = nil
                }
            }
        )
    }

    private func headerSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode == .mine ? "내 후기 관리" : "후기 피드")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(palette.textPrimary)
                    Text(mode == .mine ? "내가 작성한 후기와 작성 가능한 구매건" : "구매자가 남긴 상품 경험")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                if mode == .all {
                    Button {
                        openReviewablePurchasePicker()
                    } label: {
                        Label("작성", systemImage: "square.and.pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(palette.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                switch mode {
                case .all:
                    statPill(title: "전체", value: "\(appState.reviews.count)", palette: palette)
                    statPill(title: "평균", value: averageRatingText(for: appState.reviews), palette: palette)
                    statPill(title: "작성 가능", value: "\(appState.purchasedReviewProducts.count)", palette: palette)
                case .mine:
                    statPill(title: "내 후기", value: "\(appState.myReviews.count)", palette: palette)
                    statPill(title: "작성 가능", value: "\(appState.purchasedReviewProducts.count)", palette: palette)
                    statPill(title: "내 평균", value: averageRatingText(for: appState.myReviews), palette: palette)
                }
            }
        }
    }

    @ViewBuilder
    private func reviewablePurchasesSection(palette: AppPalette) -> some View {
        let reviewableItems = appState.reviewablePurchaseItems

        if !reviewableItems.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("작성 가능한 후기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(palette.textPrimary)

                ForEach(reviewableItems.prefix(3)) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.product?.name ?? "상품 번호 \(item.productSeq ?? 0)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(1)
                            Text(item.dateText.isEmpty ? "구매 완료" : item.dateText)
                                .font(.system(size: 12))
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer()

                        Button {
                            appState.presentReviewComposer(for: item)
                        } label: {
                            Label("쓰기", systemImage: "square.and.pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(palette.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func emptyState(palette: AppPalette) -> some View {
        VStack(spacing: 10) {
            Image(systemName: mode == .mine ? "doc.text.magnifyingglass" : "text.bubble")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            Text(mode == .mine ? "아직 작성한 후기가 없어요." : "등록된 후기가 없어요.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            if mode == .mine && appState.purchasedReviewProducts.isEmpty {
                Text("구매 완료 후 작성 가능한 상품이 생기면 여기에서 관리할 수 있어요.")
                    .font(.system(size: 12))
                    .foregroundStyle(palette.textSecondary.opacity(0.82))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
        .padding(.horizontal, 18)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reviewFeedCard(_ review: HotdogReview, palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            feedHeader(review, palette: palette)
                .padding(14)

            feedImage(review, palette: palette)
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.presentReviewDetail(review)
                }

            VStack(alignment: .leading, spacing: 12) {
                feedActionBar(review, palette: palette)

                VStack(alignment: .leading, spacing: 7) {
                    Text(review.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(2)

                    Text(review.body)
                        .font(.system(size: 14))
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(4)
                        .lineSpacing(3)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.presentReviewDetail(review)
                }

                HStack(spacing: 8) {
                    Text(review.productName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(palette.secondary.opacity(0.14), in: Capsule())

                    if review.reviewImageURL != nil {
                        Label("사진", systemImage: "photo.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    if !review.dateText.isEmpty {
                        Text(review.dateText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.presentReviewDetail(review)
                }
            }
            .padding(14)
        }
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    private func feedHeader(_ review: HotdogReview, palette: AppPalette) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(palette.secondary.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: mode == .mine ? "person.fill.checkmark" : "person.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(palette.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(mode == .mine ? "내 후기" : review.author)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                ratingStars(review.rating, palette: palette)
            }

            Spacer()

            if mode == .mine {
                HStack(spacing: 6) {
                    Button {
                        appState.presentReviewEditor(for: review)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(palette.primary)
                            .frame(width: 32, height: 32)
                            .background(palette.secondary.opacity(0.14), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        reviewPendingDeletion = review
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            } else if appState.hotdogReviewerName == review.author {
                Label("HOTDOG", systemImage: "flame.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(palette.accent, in: Capsule())
            }
        }
    }

    private func feedImage(_ review: HotdogReview, palette: AppPalette) -> some View {
        Group {
            if let reviewImageURL = review.reviewImageURL,
               let url = URL(string: reviewImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            palette.secondary.opacity(0.14)
                            ProgressView()
                                .tint(palette.primary)
                        }
                    }
                }
            } else {
                ZStack {
                    palette.secondary.opacity(0.14)
                    VStack(spacing: 8) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 28, weight: .bold))
                        Text(review.title)
                            .font(.system(size: 16, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 24)
                    }
                    .foregroundStyle(palette.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipped()
    }

    private func feedActionBar(_ review: HotdogReview, palette: AppPalette) -> some View {
        HStack(spacing: 14) {
            Button {
                appState.toggleReviewLike(for: review)
            } label: {
                Label("\(review.likes)", systemImage: appState.canLikeReview(review) ? "heart" : "heart.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(appState.canLikeReview(review) ? palette.textPrimary : palette.accent)
            }
            .buttonStyle(.plain)
            .disabled(!appState.canLikeReview(review))

            Spacer()
        }
    }

    private func averageRatingText(for reviews: [HotdogReview]) -> String {
        guard !reviews.isEmpty else { return "-" }
        let average = Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
        return String(format: "%.1f", average)
    }

    private func statPill(title: String, value: String, palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func ratingStars(_ rating: Int, palette: AppPalette) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(value <= rating ? palette.accent : palette.textSecondary.opacity(0.45))
            }
        }
    }
}

private struct ReviewablePurchaseSelectionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let palette = appState.palette
        let reviewableItems = appState.reviewablePurchaseItems

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("후기 작성할 상품 선택")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(palette.textPrimary)
                    Text("배송완료 또는 구매확정된 구매건만 후기를 작성할 수 있어요.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(.bottom, 4)

                if appState.isLoadingRemoteData && reviewableItems.isEmpty {
                    ProgressView("작성 가능한 구매건을 불러오는 중...")
                        .tint(palette.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else if reviewableItems.isEmpty {
                    emptyState(palette: palette)
                } else {
                    ForEach(reviewableItems) { item in
                        Button {
                            appState.presentReviewComposer(for: item)
                        } label: {
                            purchaseRow(item, palette: palette)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("작성 가능 상품")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await appState.loadPurchaseHistory()
        }
    }

    private func purchaseRow(_ item: PurchaseHistoryItem, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.secondary.opacity(0.14))
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(palette.primary)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.product?.name ?? "상품 번호 \(item.productSeq ?? 0)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(2)
                Text("\(item.status.title) · \(item.dateText.isEmpty ? "구매내역" : item.dateText)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                Text("수량 \(item.quantity)개 · \(item.totalPrice.formatted())원")
                    .font(.system(size: 12))
                    .foregroundStyle(palette.textSecondary.opacity(0.82))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(palette.textSecondary)
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func emptyState(palette: AppPalette) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist.unchecked")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            Text("지금 작성 가능한 구매건이 없어요.")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            Text("배송완료나 구매확정 상태가 되면 이 화면에서 상품을 선택해 후기를 작성할 수 있습니다.")
                .font(.system(size: 13))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 18)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
