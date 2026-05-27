import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var appState: AppState
    @State private var dogPendingDeletion: DogProfile?
    @State private var dogBeingEdited: DogProfile?
    @State private var refundPendingItem: PurchaseHistoryItem?
    @State private var showPurchaseHistoryPage = false
    @State private var showDogManagementPage = false

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection(palette: palette)
                    profileSummaryCard(palette: palette)
                    shortcutGrid(palette: palette)
                    purchaseHistorySection(palette: palette)
                    dogListSection(palette: palette)
                    settingsSection(palette: palette)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
            .task {
                await appState.loadPurchaseHistory()
            }
            .refreshable {
                await appState.loadPurchaseHistory()
            }
            .alert("강아지 정보를 삭제할까요?", isPresented: deleteConfirmationBinding) {
                Button("취소", role: .cancel) {
                    dogPendingDeletion = nil
                }
                Button("삭제", role: .destructive) {
                    if let dogPendingDeletion {
                        Task {
                            await appState.deleteDog(dogPendingDeletion)
                            self.dogPendingDeletion = nil
                        }
                    }
                }
            } message: {
                Text("\(dogPendingDeletion?.name ?? "선택한 강아지") 정보가 목록에서 삭제됩니다.")
            }
            .alert("환불 처리할까요?", isPresented: refundConfirmationBinding) {
                Button("아니요", role: .cancel) {
                    refundPendingItem = nil
                }
                Button("예", role: .destructive) {
                    if let refundPendingItem {
                        Task {
                            await appState.updatePurchaseStatus(refundPendingItem, action: "refund")
                            self.refundPendingItem = nil
                        }
                    }
                }
            } message: {
                Text("\(refundPendingItem?.product?.name ?? "선택한 상품") 주문을 환불 처리합니다.")
            }
            .navigationDestination(isPresented: dogEditNavigationBinding) {
                if let dog = dogBeingEdited {
                    DogEditSheet(dog: dog)
                        .environmentObject(appState)
                }
            }
            .navigationDestination(isPresented: $showPurchaseHistoryPage) {
                PurchaseHistoryView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showDogManagementPage) {
                DogManagementView()
                    .environmentObject(appState)
            }
        }
    }

    private var dogEditNavigationBinding: Binding<Bool> {
        Binding(
            get: { dogBeingEdited != nil },
            set: { isPresented in
                if !isPresented {
                    dogBeingEdited = nil
                }
            }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { dogPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    dogPendingDeletion = nil
                }
            }
        )
    }

    private var refundConfirmationBinding: Binding<Bool> {
        Binding(
            get: { refundPendingItem != nil },
            set: { isPresented in
                if !isPresented {
                    refundPendingItem = nil
                }
            }
        )
    }

    private func headerSection(palette: AppPalette) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("마이페이지")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text("구매 내역과 내 강아지 정보를 한 번에 관리하세요")
                    .font(.system(size: 14))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            Image(systemName: "gearshape")
                .foregroundStyle(palette.textSecondary)
        }
    }

    private func profileSummaryCard(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("내 프로필")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("\(appState.selectedDog.name)와 함께하는 HOTDOG")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("강아지 정보와 구매 활동을 한 번에 관리해요")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 58, height: 58)
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 10) {
                profileMetric(title: "주문", value: "\(appState.purchaseCount)")
                profileMetric(title: "쿠폰", value: "\(appState.unreadNotificationCount)")
                profileMetric(title: "포인트", value: "\(appState.favoriteCount * 200)")
            }
        }
        .padding(18)
        .background(
            palette.primary,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func profileMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func shortcutGrid(palette: AppPalette) -> some View {
        let items = [
            ("즐겨찾기", "\(appState.favoriteCount)", "heart"),
            ("장바구니", "\(appState.cartCount)", "cart"),
            ("구매내역", "\(appState.purchaseCount)", "shippingbox"),
            ("내 강아지", "\(appState.dogs.count)", "pawprint.fill")
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.0) { item in
                Button {
                    if item.0 == "즐겨찾기" {
                        appState.presentFavoriteList()
                    } else if item.0 == "장바구니" {
                        appState.showCart = true
                    } else if item.0 == "구매내역" {
                        showPurchaseHistoryPage = true
                    } else if item.0 == "내 강아지" {
                        showDogManagementPage = true
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: item.2)
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                        Text(item.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text(item.1)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(palette.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dogListSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                sectionHeader(title: "내 강아지", subtitle: "선택한 강아지에 맞춰 앱 테마가 변경돼요", palette: palette)
                Spacer()
                Button {
                    appState.beginDogOnboarding()
                } label: {
                    Label("추가", systemImage: "plus")
                        .font(.system(size: 13, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
            }

            ForEach(appState.dogs) { dog in
                SwipeableDogProfileRow(
                    dog: dog,
                    palette: palette,
                    isSelected: isSelected(dog),
                    onSelect: {
                        appState.applyTheme(for: dog)
                    },
                    onEdit: {
                        dogBeingEdited = dog
                    },
                    onDelete: {
                        dogPendingDeletion = dog
                    }
                )
            }

        }
    }

    private func purchaseHistorySection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "구매내역", subtitle: "최근 결제한 상품을 확인할 수 있어요", palette: palette)

            if appState.purchaseHistoryItems.isEmpty {
                Text("아직 구매한 상품이 없어요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(appState.purchaseHistoryItems.prefix(5)) { item in
                    purchaseHistoryRow(item: item, palette: palette)
                }
            }
        }
    }

    private func purchaseHistoryRow(item: PurchaseHistoryItem, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            if let product = item.product {
                ProductImageView(product: product, contentMode: .fit)
                    .frame(width: 58, height: 58)
                    .background(palette.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.secondary.opacity(0.14))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: "shippingbox")
                            .foregroundStyle(palette.primary)
                    )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.product?.name ?? "상품 번호 \(item.productSeq ?? 0)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)

                Text("\(item.quantity)개 · \(item.totalPrice.formatted())원")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.primary)

                if !item.dateText.isEmpty {
                    Text(item.dateText)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.textSecondary)
                }

                Text(item.status.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(statusColor(item.status, palette: palette))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(item.status, palette: palette).opacity(0.12), in: Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 7) {
                if item.status.canCancel {
                    purchaseActionButton("주문 취소", color: .red) {
                        Task { await appState.updatePurchaseStatus(item, action: "cancel") }
                    }
                }

                if item.status.canMarkDelivered {
                    purchaseActionButton("수령완료", color: palette.primary) {
                        Task { await appState.updatePurchaseStatus(item, action: "receive") }
                    }
                }

                if item.status.canConfirmOrRefund {
                    purchaseActionButton("구매확정", color: palette.primary) {
                        Task { await appState.updatePurchaseStatus(item, action: "confirm") }
                    }
                    purchaseActionButton("환불", color: .red) {
                        refundPendingItem = item
                    }
                }

                Button {
                    appState.presentReviewComposer(for: item)
                } label: {
                    Text(item.hasReview ? "작성 완료" : "후기 쓰기")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(item.hasReview || !item.status.canReview ? palette.textSecondary : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(item.hasReview || !item.status.canReview ? palette.background : palette.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(item.hasReview || !item.status.canReview)
            }
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func purchaseActionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(color.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func statusColor(_ status: PurchaseStatus, palette: AppPalette) -> Color {
        switch status {
        case .shipping:
            return palette.primary
        case .delivered:
            return palette.accent
        case .confirmed:
            return .green
        case .refundRequested:
            return palette.accent
        case .canceled, .refunded:
            return .red
        }
    }

    private func dogRowContent(dog: DogProfile, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            dogThumbnail(dog: dog)

            VStack(alignment: .leading, spacing: 5) {
                Text(dog.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text("\(dog.breed) · \(dog.age) · \(dog.weight)")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            if isSelected(dog) {
                Text("선택됨")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(palette.accent, in: Capsule())
            } else {
                Text(dog.theme.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func dogThumbnail(dog: DogProfile) -> some View {
        fallbackDogThumbnail(dog: dog)
    }

    private func fallbackDogThumbnail(dog: DogProfile) -> some View {
        ZStack {
            Circle()
                .fill(dog.theme.palette.primary)
                .frame(width: 42, height: 42)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func isSelected(_ dog: DogProfile) -> Bool {
        if let selectedSeq = appState.selectedDog.dbSeq, let dogSeq = dog.dbSeq {
            return selectedSeq == dogSeq
        }
        return appState.selectedDog.id == dog.id
    }

    private func settingsSection(palette: AppPalette) -> some View {
        let settings = ["주문배송", "쿠폰/혜택", "리뷰 관리", "알림 설정", "로그아웃"]

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "설정", subtitle: nil, palette: palette)

            ForEach(settings, id: \.self) { setting in
                Button {
                    if setting == "주문배송" {
                        showPurchaseHistoryPage = true
                    } else if setting == "리뷰 관리" {
                        appState.presentReviewList(mode: .mine)
                    } else if setting == "로그아웃" {
                        appState.logout()
                    }
                } label: {
                    HStack {
                        Text(setting)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(setting == "로그아웃" ? .red : palette.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.textSecondary)
                    }
                    .padding(16)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String?, palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(palette.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }
}

struct FavoriteListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if appState.favoriteProducts.isEmpty {
                        emptyState(
                            image: "heart",
                            title: "즐겨찾기한 상품이 없어요",
                            subtitle: "상품의 하트 버튼을 눌러 관심 상품을 모아보세요.",
                            palette: palette
                        )
                    } else {
                        ForEach(appState.favoriteProducts) { product in
                            productRow(product: product, palette: palette)
                        }
                    }
                }
                .padding(16)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("즐겨찾기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(palette.primary)
                }
            }
        }
    }

    private func productRow(product: Product, palette: AppPalette) -> some View {
        Button {
            appState.presentProductDetail(product)
        } label: {
            HStack(spacing: 12) {
                ProductImageView(product: product, contentMode: .fit)
                    .frame(width: 68, height: 68)
                    .background(palette.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    Text(product.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                    Text("\(product.price.formatted())원")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(palette.primary)
                }

                Spacer()

                Button {
                    appState.toggleFavorite(for: product)
                } label: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(palette.accent)
                        .frame(width: 34, height: 34)
                        .background(palette.background, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PurchaseHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var refundPendingItem: PurchaseHistoryItem?
    let showsCloseButton: Bool

    init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }

    var body: some View {
        let palette = appState.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if appState.purchaseHistoryItems.isEmpty {
                    emptyState(
                        image: "shippingbox",
                        title: "구매내역이 없어요",
                        subtitle: "상품을 결제하면 이곳에서 주문 내역을 확인할 수 있어요.",
                        palette: palette
                    )
                } else {
                    ForEach(appState.purchaseHistoryItems) { item in
                        purchaseRow(item: item, palette: palette)
                    }
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("구매내역")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(palette.primary)
                }
            }
        }
        .task {
            await appState.loadPurchaseHistory()
        }
        .refreshable {
            await appState.loadPurchaseHistory()
        }
        .alert("환불 처리할까요?", isPresented: refundConfirmationBinding) {
            Button("아니요", role: .cancel) {
                refundPendingItem = nil
            }
            Button("예", role: .destructive) {
                if let refundPendingItem {
                    Task {
                        await appState.updatePurchaseStatus(refundPendingItem, action: "refund")
                        self.refundPendingItem = nil
                    }
                }
            }
        } message: {
            Text("\(refundPendingItem?.product?.name ?? "선택한 상품") 주문을 환불 요청합니다.")
        }
    }

    private var refundConfirmationBinding: Binding<Bool> {
        Binding(
            get: { refundPendingItem != nil },
            set: { isPresented in
                if !isPresented {
                    refundPendingItem = nil
                }
            }
        )
    }

    private func purchaseRow(item: PurchaseHistoryItem, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            if let product = item.product {
                ProductImageView(product: product, contentMode: .fit)
                    .frame(width: 68, height: 68)
                    .background(palette.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.secondary.opacity(0.14))
                    .frame(width: 68, height: 68)
                    .overlay(Image(systemName: "shippingbox").foregroundStyle(palette.primary))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.product?.name ?? "상품 번호 \(item.productSeq ?? 0)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text("\(item.quantity)개 · \(item.totalPrice.formatted())원")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.primary)
                if !item.dateText.isEmpty {
                    Text(item.dateText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }
                Text(item.status.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(statusColor(item.status, palette: palette))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(item.status, palette: palette).opacity(0.12), in: Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 7) {
                if item.status.canCancel {
                    purchaseActionButton("주문 취소", color: .red) {
                        Task { await appState.updatePurchaseStatus(item, action: "cancel") }
                    }
                }

                if item.status.canMarkDelivered {
                    purchaseActionButton("수령완료", color: palette.primary) {
                        Task { await appState.updatePurchaseStatus(item, action: "receive") }
                    }
                }

                if item.status.canConfirmOrRefund {
                    purchaseActionButton("구매확정", color: palette.primary) {
                        Task { await appState.updatePurchaseStatus(item, action: "confirm") }
                    }
                    purchaseActionButton("환불", color: .red) {
                        refundPendingItem = item
                    }
                }

                Button {
                    appState.presentReviewComposer(for: item)
                } label: {
                    Text(item.hasReview ? "작성 완료" : "후기 쓰기")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(item.hasReview || !item.status.canReview ? palette.textSecondary : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(item.hasReview || !item.status.canReview ? palette.background : palette.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(item.hasReview || !item.status.canReview)
            }
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func purchaseActionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(color.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func statusColor(_ status: PurchaseStatus, palette: AppPalette) -> Color {
        switch status {
        case .shipping:
            return palette.primary
        case .delivered:
            return palette.accent
        case .confirmed:
            return .green
        case .refundRequested:
            return palette.accent
        case .canceled, .refunded:
            return .red
        }
    }
}

struct DogManagementView: View {
    @EnvironmentObject private var appState: AppState
    @State private var dogPendingDeletion: DogProfile?
    @State private var dogBeingEdited: DogProfile?

    var body: some View {
        let palette = appState.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("등록된 강아지 \(appState.dogs.count)마리")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(palette.textPrimary)
                        Text("선택한 강아지 기준으로 홈, 챗봇, 추천 테마가 바뀝니다.")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Button {
                        appState.beginDogOnboarding()
                    } label: {
                        Label("추가", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(palette.accent)
                }
                .padding(16)
                .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                ForEach(appState.dogs) { dog in
                    SwipeableDogProfileRow(
                        dog: dog,
                        palette: palette,
                        isSelected: isSelected(dog),
                        onSelect: {
                            appState.applyTheme(for: dog)
                        },
                        onEdit: {
                            dogBeingEdited = dog
                        },
                        onDelete: {
                            dogPendingDeletion = dog
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("내 강아지")
        .navigationBarTitleDisplayMode(.inline)
        .alert("강아지 정보를 삭제할까요?", isPresented: deleteConfirmationBinding) {
            Button("취소", role: .cancel) {
                dogPendingDeletion = nil
            }
            Button("삭제", role: .destructive) {
                if let dogPendingDeletion {
                    Task {
                        await appState.deleteDog(dogPendingDeletion)
                        self.dogPendingDeletion = nil
                    }
                }
            }
        } message: {
            Text("\(dogPendingDeletion?.name ?? "선택한 강아지") 정보가 목록에서 삭제됩니다.")
        }
        .navigationDestination(isPresented: dogEditNavigationBinding) {
            if let dog = dogBeingEdited {
                DogEditSheet(dog: dog)
                    .environmentObject(appState)
            }
        }
    }

    private var dogEditNavigationBinding: Binding<Bool> {
        Binding(
            get: { dogBeingEdited != nil },
            set: { isPresented in
                if !isPresented {
                    dogBeingEdited = nil
                }
            }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { dogPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    dogPendingDeletion = nil
                }
            }
        )
    }

    private func isSelected(_ dog: DogProfile) -> Bool {
        if let selectedSeq = appState.selectedDog.dbSeq, let dogSeq = dog.dbSeq {
            return selectedSeq == dogSeq
        }
        return appState.selectedDog.id == dog.id
    }
}

private struct SwipeableDogProfileRow: View {
    let dog: DogProfile
    let palette: AppPalette
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offsetX: CGFloat = 0

    private let actionWidth: CGFloat = 124

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 8) {
                swipeActionButton(title: "수정", systemImage: "pencil", color: palette.primary, action: onEdit)
                swipeActionButton(title: "삭제", systemImage: "trash", color: .red, action: onDelete)
            }
            .padding(.trailing, 4)

            rowContent
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            offsetX = min(0, max(value.translation.width, -actionWidth))
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                                offsetX = value.translation.width < -44 ? -actionWidth : 0
                            }
                        }
                )
                .onTapGesture {
                    if offsetX == 0 {
                        onSelect()
                    } else {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            offsetX = 0
                        }
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(dog.theme.palette.primary)
                    .frame(width: 42, height: 42)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(dog.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text("\(dog.breed) · \(dog.age) · \(dog.weight)")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            if isSelected {
                Text("선택됨")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(palette.accent, in: Capsule())
            } else {
                Text(dog.theme.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func swipeActionButton(title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                offsetX = 0
            }
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: 54, height: 68)
            .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct DogEditSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let dog: DogProfile

    @State private var name: String
    @State private var breed: String
    @State private var age: String
    @State private var weight: String
    @State private var theme: DogColorTheme

    private let breeds = ["몰티즈", "푸들", "믹스견", "포메라니안", "비숑 프리제", "치와와", "시츄", "진돗개", "요크셔테리어", "골든 리트리버", "기타"]
    private let ages = ["1살 미만", "1살", "2살", "3살", "4살", "5살", "6살", "7살", "8살", "9살", "10살 이상"]
    private let weights = ["1kg 미만", "1-3kg", "3-6kg", "6-10kg", "10-15kg", "15-20kg", "20-30kg", "30kg 이상"]

    init(dog: DogProfile) {
        self.dog = dog
        _name = State(initialValue: dog.name)
        _breed = State(initialValue: dog.breed)
        _age = State(initialValue: dog.age)
        _weight = State(initialValue: dog.weight)
        _theme = State(initialValue: dog.theme)
    }

    var body: some View {
        let palette = theme.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dogPhotoPreview(palette: palette)

                    TextField("이름", text: $name)
                        .textFieldStyle(.roundedBorder)

                    pickerField("견종", selection: $breed, options: breeds, palette: palette)
                    pickerField("나이", selection: $age, options: ages, palette: palette)
                    pickerField("몸무게", selection: $weight, options: weights, palette: palette)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("대표 색상")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(palette.textPrimary)

                        HStack(spacing: 8) {
                            ForEach(DogColorTheme.allCases) { colorTheme in
                                Button {
                                    theme = colorTheme
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(colorTheme.palette.primary)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(theme == colorTheme ? palette.accent : Color.black.opacity(0.12), lineWidth: theme == colorTheme ? 3 : 1)
                                            )
                                        Text(colorTheme.displayName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(palette.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(theme == colorTheme ? palette.accent.opacity(0.14) : palette.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        Task {
                            let success = await appState.updateDog(dog, name: name, breed: breed, age: age, weight: weight, theme: theme)
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if appState.isSavingDogProfile {
                                ProgressView().tint(.white)
                            } else {
                                Text("수정 완료")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? palette.primary : palette.textSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid || appState.isSavingDogProfile)
                }
                .padding(20)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("강아지 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(palette.primary)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func dogPhotoPreview(palette: AppPalette) -> some View {
        if let imageURL = dog.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackDogPhoto(palette: palette)
                case .empty:
                    ProgressView()
                        .tint(palette.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                @unknown default:
                    fallbackDogPhoto(palette: palette)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            fallbackDogPhoto(palette: palette)
        }
    }

    private func fallbackDogPhoto(palette: AppPalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.cardBackground)
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(palette.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    private func pickerField(_ title: String, selection: Binding<String>, options: [String], palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private func emptyState(image: String, title: String, subtitle: String, palette: AppPalette) -> some View {
    VStack(spacing: 12) {
        Image(systemName: image)
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(palette.textSecondary)
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(palette.textPrimary)
        Text(subtitle)
            .font(.system(size: 14))
            .foregroundStyle(palette.textSecondary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
    .padding(.horizontal, 20)
    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
}
