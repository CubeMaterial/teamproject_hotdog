import SwiftUI

struct CartView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            VStack(spacing: 0) {
                if appState.cartItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 36))
                            .foregroundStyle(palette.textSecondary)
                        Text("장바구니가 비어 있어요")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text("마음에 드는 상품을 담아보세요.")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appState.cartItems) { item in
                                HStack(spacing: 14) {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(palette.secondary.opacity(0.14))
                                        .frame(width: 72, height: 72)
                                        .overlay(
                                            ProductImageView(product: item.product, contentMode: .fit)
                                                .padding(6)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.product.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(palette.textPrimary)
                                        Text(item.product.description)
                                            .font(.system(size: 12))
                                            .foregroundStyle(palette.textSecondary)
                                            .lineLimit(2)
                                        Text("\(item.product.price.formatted())원 · \(item.quantity)개")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(palette.primary)
                                    }

                                    Spacer()

                                    HStack(spacing: 8) {
                                        Button {
                                            appState.decreaseCartQuantity(for: item.product)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(palette.accent)
                                        }
                                        .buttonStyle(.plain)

                                        Text("\(item.quantity)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(palette.textPrimary)
                                            .frame(minWidth: 20)

                                        Button {
                                            appState.increaseCartQuantity(for: item.product)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(palette.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                                .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .onTapGesture {
                                    appState.presentProductDetail(item.product)
                                }
                            }
                        }
                        .padding(16)
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text("총 결제 금액")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(palette.textSecondary)
                            Spacer()
                            Text("\(appState.cartTotalPrice.formatted())원")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(palette.textPrimary)
                        }

                        Button {
                            appState.startCartCheckout()
                        } label: {
                            Text("결제 진행")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(palette.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(palette.background)
                }
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("장바구니")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !appState.cartItems.isEmpty {
                        Button("비우기") {
                            appState.clearCart()
                        }
                        .foregroundStyle(palette.primary)
                    }
                }
            }
        }
    }
}
