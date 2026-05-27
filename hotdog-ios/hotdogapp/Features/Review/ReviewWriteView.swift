import PhotosUI
import SwiftUI
import UIKit

struct ReviewWriteView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let editingReview: HotdogReview?

    @State private var selectedProductName = ""
    @State private var title = ""
    @State private var bodyText = ""
    @State private var rating = 5
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var reviewImage: UIImage?
    @State private var reviewImagePayload: String?
    @State private var isCheckingReviewText = false
    @State private var moderationAlertMessage: String?

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if selectedProductName.isEmpty && editingReview == nil {
                        Text("후기를 작성할 구매건을 먼저 선택해주세요.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    }

                    formSection(title: "작성 상품", palette: palette) {
                        selectedProductCard(palette: palette)
                    }

                    formSection(title: "만족도", palette: palette) {
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    rating = value
                                } label: {
                                    Image(systemName: value <= rating ? "star.fill" : "star")
                                        .font(.system(size: 24))
                                        .foregroundStyle(value <= rating ? palette.accent : palette.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    formSection(title: "제목", palette: palette) {
                        textField("후기 제목을 입력하세요", text: $title, palette: palette)
                    }

                    formSection(title: "상세 내용", palette: palette) {
                        TextField("사용 경험을 자세히 적어주세요", text: $bodyText, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(6, reservesSpace: true)
                            .padding(14)
                            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    formSection(title: "사진", palette: palette) {
                        reviewPhotoSection(palette: palette)
                    }

                    Button {
                        Task {
                            await submitReview()
                        }
                    } label: {
                        Group {
                            if isCheckingReviewText {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(editingReview == nil ? "후기 등록" : "후기 수정")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(isFormValid ? palette.primary : palette.textSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormValid || isCheckingReviewText)
                }
                .padding(20)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle(editingReview == nil ? "후기 작성" : "후기 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(palette.primary)
                }
            }
            .onAppear {
                if let editingReview {
                    selectedProductName = editingReview.productName
                    title = editingReview.title
                    bodyText = editingReview.body
                    rating = editingReview.rating
                } else if selectedProductName.isEmpty {
                    selectedProductName = appState.reviewDraftProductName
                }
            }
            .onDisappear {
                appState.reviewDraftProductName = ""
                appState.reviewDraftBuySeq = nil
                appState.editingReview = nil
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await loadReviewPhoto(from: newItem)
                }
            }
            .alert("후기 등록 불가", isPresented: moderationAlertBinding) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(moderationAlertMessage ?? "")
            }
        }
    }

    private var productOptions: [String] {
        if let editingReview {
            return [editingReview.productName]
        }
        return appState.reviewablePurchaseItems.compactMap { $0.product?.name }
    }

    private var isFormValid: Bool {
        !selectedProductName.isEmpty &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var moderationAlertBinding: Binding<Bool> {
        Binding(
            get: { moderationAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    moderationAlertMessage = nil
                }
            }
        )
    }

    private func formSection<Content: View>(title: String, palette: AppPalette, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            content()
        }
    }

    private func textField(_ title: String, text: Binding<String>, palette: AppPalette) -> some View {
        TextField(title, text: text)
            .font(.system(size: 14))
            .foregroundStyle(palette.textPrimary)
            .padding(14)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectedProductCard(palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selectedProductName.isEmpty ? "exclamationmark.circle" : "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(selectedProductName.isEmpty ? palette.textSecondary : palette.primary)
                .frame(width: 42, height: 42)
                .background(palette.secondary.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedProductName.isEmpty ? "선택된 구매건 없음" : selectedProductName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text(editingReview == nil ? "선택한 구매건으로 후기를 작성합니다." : "작성 상품은 수정할 수 없습니다.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reviewPhotoSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let reviewImage {
                Image(uiImage: reviewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(reviewImage == nil ? "사진 추가" : "사진 변경", systemImage: "photo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(palette.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if reviewImage != nil {
                    Button {
                        selectedPhotoItem = nil
                        reviewImage = nil
                        reviewImagePayload = nil
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(width: 46, height: 46)
                            .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @MainActor
    private func loadReviewPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let resized = image.resizedForReview(maxDimension: 900)
        reviewImage = resized
        if let jpegData = resized.jpegData(compressionQuality: 0.72) {
            reviewImagePayload = "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        }
    }

    @MainActor
    private func submitReview() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let moderationText = "\(trimmedTitle)\n\(trimmedBody)"

        isCheckingReviewText = true
        let moderationResult = await appState.validateReviewText(moderationText)
        isCheckingReviewText = false

        guard moderationResult.isAllowed else {
            moderationAlertMessage = moderationResult.message
            return
        }

        let isSuccess: Bool
        if let editingReview {
            isSuccess = await appState.updateReview(
                editingReview,
                title: trimmedTitle,
                body: trimmedBody,
                rating: rating,
                reviewImage: reviewImagePayload
            )
        } else {
            isSuccess = await appState.addReview(
                title: trimmedTitle,
                productName: selectedProductName,
                summary: "",
                body: trimmedBody,
                rating: rating,
                reviewImage: reviewImagePayload
            )
        }

        if isSuccess {
            dismiss()
        }
    }
}

private extension UIImage {
    func resizedForReview(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
