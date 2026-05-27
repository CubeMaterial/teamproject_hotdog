import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject private var appState: AppState

    let product: Product
    @State private var selectedQuantity = 1

    var body: some View {
        let palette = appState.palette

        VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .fill(palette.cardBackground)
                                .frame(height: 360)
                                .overlay(
                                    ProductImageView(product: product, contentMode: .fit)
                                        .padding(20)
                                )

                            Text("1 / 3")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.5), in: Capsule())
                                .padding(16)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("강아지 전용")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(palette.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(palette.accent.opacity(0.12), in: Capsule())

                                Text(product.category)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(palette.textSecondary)

                                Spacer()

                                Button {
                                    appState.toggleFavorite(for: product)
                                } label: {
                                    Image(systemName: appState.favoriteProductIDs.contains(product.id) ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(appState.favoriteProductIDs.contains(product.id) ? palette.accent : palette.textSecondary)
                                        .frame(width: 34, height: 34)
                                        .background(palette.cardBackground, in: Circle())
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(product.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(palette.textPrimary)
                                Text(product.description)
                                    .font(.system(size: 14))
                                    .foregroundStyle(palette.textSecondary)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(product.discountText)
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundStyle(palette.accent)
                                Text("\(product.price.formatted())원")
                                    .font(.system(size: 34, weight: .heavy))
                                    .foregroundStyle(palette.textPrimary)
                            }

                            Divider()

                            detailRow(title: "배송", value: "무료배송 · 오늘 주문 시 내일 도착 예정", palette: palette)
                            detailRow(title: "재고", value: product.isSoldOut ? "품절" : "\(product.stockQuantity)개", palette: palette)
                            detailRow(title: "추천", value: "\(appState.selectedDog.name)에게 잘 맞는 인기 상품", palette: palette)
                            quantitySelector(palette: palette)

                            Button {
                                appState.presentReviewComposer(for: product)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("후기 작성")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(palette.textPrimary)
                                        Text(appState.canReview(product) ? "사용 후기를 남기고 다른 집사와 경험을 공유해보세요" : "구매한 상품만 후기를 작성할 수 있어요")
                                            .font(.system(size: 13))
                                            .foregroundStyle(palette.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "square.and.pencil")
                                        .foregroundStyle(palette.accent)
                                }
                                .padding(16)
                                .background(palette.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(!appState.canReview(product))
                            .opacity(appState.canReview(product) ? 1 : 0.65)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            appState.addToCart(product, quantity: selectedQuantity)
                        } label: {
                            Text(product.isSoldOut ? "품절" : "장바구니 담기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(product.isSoldOut ? palette.textSecondary : palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(product.isSoldOut)

                        Button {
                            appState.startCheckout(for: product, quantity: selectedQuantity)
                        } label: {
                            Text(product.isSoldOut ? "구매 불가" : "바로 구매")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(product.isSoldOut ? palette.textSecondary : palette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(product.isSoldOut)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("상품상세정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            appState.toggleFavorite(for: product)
                        } label: {
                            Image(systemName: appState.favoriteProductIDs.contains(product.id) ? "heart.fill" : "heart")
                                .foregroundStyle(appState.favoriteProductIDs.contains(product.id) ? palette.accent : palette.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            appState.showCart = true
                        } label: {
                            Image(systemName: "bag")
                                .foregroundStyle(palette.textPrimary)
                        }
                    }
                }
            }
        }

    private var maxQuantity: Int {
        min(max(product.stockQuantity, 1), 20)
    }

    private func quantitySelector(palette: AppPalette) -> some View {
        HStack(spacing: 14) {
            Text("수량")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 44, alignment: .leading)

            Stepper(value: $selectedQuantity, in: 1...maxQuantity) {
                Text("\(selectedQuantity)개")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(palette.primary)
            }
            .disabled(product.isSoldOut)
        }
        .padding(.vertical, 4)
        .onChange(of: product.stockQuantity) { _, _ in
            selectedQuantity = min(selectedQuantity, maxQuantity)
        }
    }

    private func detailRow(title: String, value: String, palette: AppPalette) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(palette.textSecondary)
            Spacer()
        }
    }
}
