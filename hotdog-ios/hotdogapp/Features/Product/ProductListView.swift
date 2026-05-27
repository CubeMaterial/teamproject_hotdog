import SwiftUI

struct ProductListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var visibleProductCount = 10

    private let pageSize = 10
    private let categories = ["전체", "사료", "간식", "의류", "목줄", "하네스", "장난감"]

    var body: some View {
        let palette = appState.palette
        let filteredProducts = appState.filteredCatalogProducts
        let displayedProducts = Array(filteredProducts.prefix(visibleProductCount))

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("제품")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(palette.textPrimary)

                    searchBar(palette: palette)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                categoryChip(category, palette: palette, isSelected: appState.selectedProductCategory == category)
                            }
                        }
                    }

                    if appState.isLoadingRemoteData && appState.products.isEmpty {
                        ProgressView("상품을 불러오는 중...")
                            .tint(palette.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }

                    if let apiErrorMessage = appState.apiErrorMessage, appState.products.isEmpty {
                        Text(apiErrorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !appState.isLoadingRemoteData && filteredProducts.isEmpty {
                        Text("조건에 맞는 상품이 없어요.")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }

                    HStack {
                        Text("총 \(filteredProducts.count)개 중 \(displayedProducts.count)개 표시")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.textSecondary)
                        Spacer()
                    }

                    ForEach(displayedProducts) { product in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(product.isSoldOut ? Color.gray.opacity(0.18) : palette.secondary.opacity(0.15))
                                    .frame(width: 96, height: 96)
                                    .overlay(
                                        ProductImageView(product: product, contentMode: .fit)
                                            .padding(8)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(product.category)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(product.isSoldOut ? palette.textSecondary : palette.accent)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background((product.isSoldOut ? Color.gray : palette.accent).opacity(0.12), in: Capsule())
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Button {
                                                appState.toggleFavorite(for: product)
                                            } label: {
                                                Image(systemName: appState.favoriteProductIDs.contains(product.id) ? "heart.fill" : "heart")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(appState.favoriteProductIDs.contains(product.id) ? palette.accent : palette.textSecondary)
                                                    .frame(width: 30, height: 30)
                                                    .background(palette.cardBackground, in: Circle())
                                            }
                                            .buttonStyle(.plain)

                                            Text(product.isSoldOut ? "품절" : product.discountText)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(product.isSoldOut ? Color.red : palette.primary, in: Capsule())
                                        }
                                    }

                                    Text(product.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(product.isSoldOut ? palette.textSecondary : palette.textPrimary)
                                    Text(product.description)
                                        .font(.system(size: 13))
                                        .foregroundStyle(palette.textSecondary)
                                        .lineLimit(2)
                                    Text("\(product.price.formatted())원")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(product.isSoldOut ? palette.textSecondary : palette.textPrimary)
                                }

                                Spacer(minLength: 0)
                            }

                            HStack(spacing: 10) {
                                actionButton(
                                    title: product.isSoldOut ? "품절" : "장바구니",
                                    fill: palette.cardBackground,
                                    textColor: palette.primary,
                                    stroke: palette.primary,
                                    isDisabled: product.isSoldOut,
                                    action: { appState.addToCart(product) }
                                )
                                actionButton(
                                    title: product.isSoldOut ? "구매 불가" : "바로 구매",
                                    fill: product.isSoldOut ? palette.textSecondary : palette.accent,
                                    textColor: .white,
                                    stroke: product.isSoldOut ? palette.textSecondary : palette.accent,
                                    isDisabled: product.isSoldOut,
                                    action: { appState.startCheckout(for: product) }
                                )
                            }
                        }
                        .padding(16)
                        .background(product.isSoldOut ? Color.gray.opacity(0.12) : palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                        .opacity(product.isSoldOut ? 0.78 : 1)
                        .onTapGesture {
                            appState.presentProductDetail(product)
                        }
                    }

                    if displayedProducts.count < filteredProducts.count {
                        Button {
                            visibleProductCount = min(visibleProductCount + pageSize, filteredProducts.count)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("상품 10개 더 보기")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(palette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
            .onChange(of: appState.selectedProductCategory) {
                resetPagination()
            }
            .onChange(of: appState.productSearchText) {
                resetPagination()
            }
            .onChange(of: appState.products.count) {
                resetPagination()
            }
        }
    }

    private func resetPagination() {
        visibleProductCount = pageSize
    }

    private func searchBar(palette: AppPalette) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.textSecondary)
            TextField("제품명을 검색해보세요", text: $appState.productSearchText)
                .font(.system(size: 14))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func categoryChip(_ title: String, palette: AppPalette, isSelected: Bool) -> some View {
        Button {
            appState.setProductCategory(title)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : palette.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? palette.primary : palette.cardBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func actionButton(title: String, fill: Color, textColor: Color, stroke: Color, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}
