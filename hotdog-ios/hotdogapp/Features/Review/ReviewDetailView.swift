import SwiftUI

struct ReviewDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let review: HotdogReview

    var body: some View {
        let palette = appState.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerSection(palette: palette)
                contentSection(palette: palette)
                helpfulButton(palette: palette)
            }
            .padding(20)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("후기 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    appState.selectedReview = nil
                    dismiss()
                } label: {
                    Label("뒤로", systemImage: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(palette.textPrimary)
            }
        }
    }

    private func headerSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(review.productName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(palette.secondary.opacity(0.14), in: Capsule())
                Spacer()
                Text(review.dateText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }

            Text(review.title)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let reviewImageURL = review.reviewImageURL,
               let url = URL(string: reviewImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        palette.secondary.opacity(0.14)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                ratingStars(review.rating, palette: palette)
                Text(review.author)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                if !review.breed.isEmpty {
                    Text(review.breed)
                        .font(.system(size: 13))
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .padding(18)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func contentSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(review.body)
                .font(.system(size: 15))
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func helpfulButton(palette: AppPalette) -> some View {
        Button {
            appState.toggleReviewLike(for: currentReview)
        } label: {
            HStack {
                Spacer()
                Label(helpfulButtonTitle, systemImage: appState.canLikeReview(currentReview) ? "heart" : "heart.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 15)
            .background(appState.canLikeReview(currentReview) ? palette.accent : palette.textSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!appState.canLikeReview(currentReview))
    }

    private func ratingStars(_ rating: Int, palette: AppPalette) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(value <= rating ? palette.accent : palette.textSecondary.opacity(0.45))
            }
        }
    }

    private var currentLikes: Int {
        currentReview.likes
    }

    private var currentReview: HotdogReview {
        if let dbSeq = review.dbSeq {
            return appState.reviews.first(where: { $0.dbSeq == dbSeq }) ?? review
        }
        return appState.reviews.first(where: { $0.id == review.id }) ?? review
    }

    private var helpfulButtonTitle: String {
        if !appState.canLikeReview(currentReview) {
            return "도움됨 \(currentLikes)"
        }
        return "도움이 됐어요 \(currentLikes)"
    }
}
