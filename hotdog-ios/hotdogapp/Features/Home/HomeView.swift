import CoreLocation
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showWalkGuide = false
    @State private var showHospitalSheet = false
    @State private var dogDetailSelection: DogProfile?
    @StateObject private var hospitalFinder = NearbyHospitalFinder()

    private var dogDetailNavigationBinding: Binding<Bool> {
        Binding(
            get: { dogDetailSelection != nil },
            set: { isPresented in
                if !isPresented {
                    dogDetailSelection = nil
                }
            }
        )
    }

    private let menuItems: [(title: String, systemImage: String)] = [
        ("사료", "bag.fill"),
        ("간식", "carrot.fill"),
        ("장난감", "tennisball.fill"),
        ("의류", "tshirt.fill"),
        ("목줄", "link"),
        ("하네스", "figure.walk"),
        ("후기", "text.bubble.fill"),
        ("반려견", "pawprint.circle.fill"),
        ("병원", "cross.case.fill"),
        ("산책", "figure.walk")
    ]

    var body: some View {
        let palette = appState.palette
        let isSearching = !appState.homeSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topHeader(palette: palette)
                    searchBar(palette: palette)
                    bannerSection(palette: palette)
                    iconMenuSection(palette: palette)
                    dogThemePicker(palette: palette)
                    productGridSection(
                        title: isSearching ? "검색 결과" : "추천 상품",
                        subtitle: isSearching ? "'\(appState.homeSearchText)' 검색 결과" : "단추에게 맞춘 큐레이션",
                        products: Array(appState.filteredHomeProducts.prefix(4)),
                        palette: palette
                    )

                    if appState.isLoadingRemoteData && appState.products.isEmpty {
                        ProgressView("상품을 불러오는 중...")
                            .tint(palette.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }

                    if let apiErrorMessage = appState.apiErrorMessage, appState.products.isEmpty {
                        Text(apiErrorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !isSearching {
                        widePromotionSection(palette: palette)
                        reviewListSection(palette: palette)
                        aiShortcutSection(palette: palette)
                    } else {
                        searchActionSection(palette: palette)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showWalkGuide) {
                walkGuideSheet
            }
            .navigationDestination(isPresented: $showHospitalSheet) {
                hospitalsSheet
                    .onAppear {
                        hospitalFinder.refreshNearbyHospitals()
                    }
            }
            .navigationDestination(isPresented: dogDetailNavigationBinding) {
                if let dog = dogDetailSelection {
                    DogDetailSheet(dog: dog)
                }
            }
        }
    }

    private func topHeader(palette: AppPalette) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HOTDOG")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(palette.accent)
                Text("\(appState.currentUserDisplayName)님, \(appState.selectedDog.name) 맞춤 추천이 도착했어요")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    appState.selectedTab = .notifications
                } label: {
                    headerIcon(systemImage: "bell.badge", badge: appState.unreadNotificationCount, palette: palette)
                }
                .buttonStyle(.plain)

                Button {
                    appState.showCart = true
                } label: {
                    headerIcon(systemImage: "cart", badge: appState.cartCount, palette: palette)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func headerIcon(systemImage: String, badge: Int, palette: AppPalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.cardBackground)
                .frame(width: 42, height: 42)
            Image(systemName: systemImage)
                .foregroundStyle(palette.textPrimary)
            if badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(palette.accent, in: Circle())
                    .offset(x: 14, y: -14)
            }
        }
        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
    }

    private func searchBar(palette: AppPalette) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.textSecondary)
            TextField("사료, 간식, 장난감을 검색해보세요", text: $appState.homeSearchText)
                .font(.system(size: 14))
                .onSubmit {
                    submitHomeSearch()
                }
            Spacer()
            if !appState.homeSearchText.isEmpty {
                Button {
                    appState.homeSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textSecondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                submitHomeSearch()
            } label: {
                Text("검색")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(palette.primary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(appState.homeSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(appState.homeSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
    }

    private func bannerSection(palette: AppPalette) -> some View {
        Button {
            dogDetailSelection = appState.selectedDog
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.primary)
                    .frame(height: 168)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("내새꾸 맞춤 추천")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("\(appState.selectedDog.name)에게 딱 맞는\n추천 서비스")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("구매 이력과 견종 정보를 반영했어요")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer()

                    dogAvatar(for: appState.selectedDog, size: 88, imageSize: 78, palette: palette)
                        .id("\(appState.selectedDog.id.uuidString)-\(appState.selectedDog.breed)-\(appState.selectedDog.imageURL ?? "")")
                }
                .padding(.horizontal, 20)
            }
        }
        .buttonStyle(.plain)
    }

    private func dogAvatar(for dog: DogProfile, size: CGFloat, imageSize: CGFloat, palette: AppPalette) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: size, height: size)

            dogBreedImage(for: dog, imageSize: imageSize, palette: palette)
        }
    }

    @ViewBuilder
    private func dogBreedImage(for dog: DogProfile, imageSize: CGFloat, palette: AppPalette) -> some View {
        let assetName = dogImageAssetName(for: dog.breed)
        fallbackDogBreedImage(assetName: assetName, imageSize: imageSize, palette: palette)
    }

    @ViewBuilder
    private func fallbackDogBreedImage(assetName: String, imageSize: CGFloat, palette: AppPalette) -> some View {
        if let uiImage = dogBreedUIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: imageSize * 0.74))
                .foregroundStyle(palette.primary)
                .frame(width: imageSize, height: imageSize)
                .background(.white.opacity(0.86), in: Circle())
        }
    }

    private func dogBreedUIImage(named assetName: String) -> UIImage? {
        let candidates = [
            assetName,
            assetName.precomposedStringWithCanonicalMapping,
            assetName.decomposedStringWithCanonicalMapping
        ]

        for candidate in candidates {
            if let image = UIImage(named: candidate) {
                return image
            }
        }
        return nil
    }

    private func dogImageAssetName(for breed: String) -> String {
        let normalizedBreed = breed
            .precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        if normalizedBreed.contains("푸들") {
            return "dog_poodle"
        }
        if normalizedBreed.contains("진도") || normalizedBreed.contains("진돗") || normalizedBreed.contains("jindo") {
            return "dog_jindo"
        }
        if normalizedBreed.contains("비숑") || normalizedBreed.contains("bichon") {
            return "dog_bichon"
        }
        if normalizedBreed.contains("몰티즈") || normalizedBreed.contains("말티즈") || normalizedBreed.contains("maltese") {
            return "dog_maltese"
        }
        if normalizedBreed.contains("요크셔") || normalizedBreed.contains("yorkshire") {
            return "dog_yorkshire"
        }
        if normalizedBreed.contains("골든") || normalizedBreed.contains("리트리버") || normalizedBreed.contains("retriever") {
            return "dog_golden_retriever"
        }
        if normalizedBreed.contains("포메") || normalizedBreed.contains("pomeranian") {
            return "dog_pomeranian"
        }
        if normalizedBreed.contains("믹스") || normalizedBreed.contains("mix") || normalizedBreed.contains("mixed") {
            return "dog_mixed"
        }
        if normalizedBreed.contains("치와와") || normalizedBreed.contains("chihuahua") {
            return "dog_chihuahua"
        }
        if normalizedBreed.contains("시츄") || normalizedBreed.contains("시추") || normalizedBreed.contains("shihtzu") || normalizedBreed.contains("shih-tzu") {
            return "dog_shih_tzu"
        }
        return "dog_default"
    }

    private func iconMenuSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "카테고리", subtitle: nil, palette: palette)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                ForEach(menuItems, id: \.title) { item in
                    Button {
                        handleMenuTap(item.title)
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(palette.accent)
                                .frame(width: 40, height: 40)
                                .background(palette.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text(item.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dogThemePicker(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "내 강아지", subtitle: "털색에 따라 앱 테마가 바뀌어요", palette: palette)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.dogs) { dog in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                appState.applyTheme(for: dog)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                dogAvatar(for: dog, size: 34, imageSize: 30, palette: palette)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(dog.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(palette.textPrimary)
                                    Text(dog.breed)
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.textSecondary)
                                }

                                if appState.selectedDog.id == dog.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(palette.accent)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(palette.cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func productGridSection(title: String, subtitle: String, products: [Product], palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: title, subtitle: subtitle, palette: palette)

            if products.isEmpty {
                Text("검색 결과가 없어요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(products) { product in
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(product.isSoldOut ? Color.gray.opacity(0.18) : palette.secondary.opacity(0.16))
                                .frame(height: 118)

                            Text(product.isSoldOut ? "품절" : product.discountText)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(product.isSoldOut ? Color.red : palette.accent, in: Capsule())
                                .padding(10)

                            ProductImageView(product: product, contentMode: .fit)
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }

                        Text(product.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(product.isSoldOut ? palette.textSecondary : palette.textPrimary)
                            .lineLimit(2)
                        Text(product.description)
                            .font(.system(size: 12))
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                        Text("\(product.price.formatted())원")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(product.isSoldOut ? palette.textSecondary : palette.textPrimary)

                        HStack(spacing: 8) {
                            Button {
                                appState.toggleFavorite(for: product)
                            } label: {
                                Image(systemName: appState.favoriteProductIDs.contains(product.id) ? "heart.fill" : "heart")
                                    .foregroundStyle(appState.favoriteProductIDs.contains(product.id) ? palette.accent : palette.textSecondary)
                                    .frame(width: 34, height: 34)
                                    .background(palette.background, in: Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                appState.addToCart(product)
                            } label: {
                                Text(product.isSoldOut ? "품절" : "담기")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(product.isSoldOut ? palette.textSecondary : palette.primary, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(product.isSoldOut)

                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(product.isSoldOut ? Color.gray.opacity(0.12) : palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                    .opacity(product.isSoldOut ? 0.78 : 1)
                    .onTapGesture {
                        appState.presentProductDetail(product)
                    }
                    }
                }
            }
        }
    }

    private func widePromotionSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "지금 인기 기획전", subtitle: nil, palette: palette)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardBackground)
                .frame(height: 164)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("건강한 하루를 위한\n데일리 케어 10%")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(palette.textPrimary)
                        Text("사료, 영양제, 데일리 간식 묶음 특가")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.textSecondary)
                        Text("오늘만 보기")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(palette.primary, in: Capsule())
                    }
                    .padding(.horizontal, 20)
                }
        }
    }

    private func reviewListSection(palette: AppPalette) -> some View {
        let topReviews = Array(appState.sortedReviews.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "HOTDOG 인기 후기", subtitle: "좋아요 많은 후기 TOP 5", palette: palette)

            ForEach(Array(topReviews.enumerated()), id: \.element.id) { index, review in
                popularReviewCard(review, rank: index + 1, palette: palette)
            }
        }
    }

    private func popularReviewCard(_ review: HotdogReview, rank: Int, palette: AppPalette) -> some View {
        let isTopReview = rank == 1

        return HStack(alignment: .top, spacing: 12) {
            reviewThumbnail(review, palette: palette)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    if isTopReview {
                        Label("인기 1위", systemImage: "crown.fill")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(palette.accent, in: Capsule())
                    } else {
                        Text("TOP \(rank)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(palette.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(palette.secondary.opacity(0.14), in: Capsule())
                    }

                    Spacer(minLength: 0)
                }

                Text(review.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(review.author)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.primary)
                    if appState.hotdogReviewerName == review.author {
                        Text("HOTDOG")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(palette.accent, in: Capsule())
                    }
                    Text(review.breed)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    Button {
                        appState.toggleReviewLike(for: review)
                    } label: {
                        Label("\(review.likes)", systemImage: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(appState.canLikeReview(review) ? palette.accent : palette.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.canLikeReview(review))
                }
            }
        }
        .padding(14)
        .background(
            isTopReview ? palette.accent.opacity(0.16) : palette.cardBackground,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isTopReview ? palette.accent.opacity(0.65) : Color.clear, lineWidth: 1.4)
        )
        .shadow(color: isTopReview ? palette.accent.opacity(0.18) : .black.opacity(0.05), radius: isTopReview ? 16 : 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            appState.presentReviewDetail(review)
        }
    }

    @ViewBuilder
    private func reviewThumbnail(_ review: HotdogReview, palette: AppPalette) -> some View {
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
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.secondary.opacity(0.14))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "quote.bubble.fill")
                        .foregroundStyle(palette.primary)
                )
        }
    }

    private func aiShortcutSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "반려견 프로필", subtitle: "사진과 기본 정보를 등록하고 맞춤 상품을 추천받아요", palette: palette)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("프로필 등록")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("반려견 정보 입력하기")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.88))
                }

                Spacer()

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(palette.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onTapGesture {
                appState.beginDogOnboarding()
            }
        }
    }

    private func searchActionSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "전체 상품에서 더 보기", subtitle: "제품 탭에서 전체 검색 결과를 확인할 수 있어요", palette: palette)

            Button {
                appState.productSearchText = appState.homeSearchText
                appState.selectedTab = .products
            } label: {
                HStack {
                    Text("제품 페이지에서 검색 결과 보기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.white)
                }
                .padding(16)
                .background(palette.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func handleMenuTap(_ title: String) {
        switch title {
        case "사료", "간식", "장난감", "의류", "목줄", "하네스":
            appState.setProductCategory(title)
            appState.selectedTab = .products
        case "반려견":
            appState.beginDogOnboarding()
        case "산책":
            appState.selectedTab = .walk
        case "병원":
            showHospitalSheet = true
        case "후기":
            appState.presentReviewList()
        default:
            appState.selectedTab = .notifications
        }
    }

    private func submitHomeSearch() {
        let keyword = appState.homeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        appState.productSearchText = keyword
        appState.selectedTab = .products
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

    private var walkGuideSheet: some View {
        let palette = appState.palette

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(appState.selectedDog.name) 산책 가이드")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text("\(appState.selectedDog.breed) · \(appState.selectedDog.age) · \(appState.selectedDog.weight)")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.textSecondary)
                }

                walkGuideCard(
                    title: "추천 산책 시간",
                    detail: "하루 2회, 한 번에 20~30분 정도가 적당해요.",
                    systemImage: "clock.fill",
                    palette: palette
                )
                walkGuideCard(
                    title: "오늘 체크할 것",
                    detail: "하네스 착용, 물 챙기기, 발바닥 상태 확인",
                    systemImage: "checklist",
                    palette: palette
                )
                walkGuideCard(
                    title: "주의 포인트",
                    detail: "더운 시간대는 피하고, 흥분도가 높으면 노즈워크로 마무리해보세요.",
                    systemImage: "exclamationmark.shield.fill",
                    palette: palette
                )

                Button {
                    showWalkGuide = false
                    appState.showChatbot = true
                    Task {
                        await appState.askChatbot(question: "\(appState.selectedDog.name) 산책 루틴 추천")
                    }
                } label: {
                    Text("챗봇으로 더 자세히 보기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("산책 가이드")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func walkGuideCard(title: String, detail: String, systemImage: String, palette: AppPalette) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.secondary.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: systemImage)
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var hospitalsSheet: some View {
        let palette = appState.palette

        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("추천 병원")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text("현재 위치 기준 근처 동물병원 3~5곳")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.textSecondary)
                }

                if hospitalFinder.isLoading {
                    ProgressView("근처 병원을 찾는 중...")
                        .tint(palette.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if let errorMessage = hospitalFinder.errorMessage {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(palette.textSecondary)
                        Button {
                            hospitalFinder.refreshNearbyHospitals()
                        } label: {
                            Text("다시 시도")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(palette.primary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    ForEach(hospitalFinder.hospitals, id: \.id) { hospital in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(hospital.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(palette.textPrimary)
                                Spacer()
                                Text(formattedDistance(hospital.distance))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(palette.accent)
                            }
                            Text(hospital.address)
                                .font(.system(size: 13))
                                .foregroundStyle(palette.textSecondary)
                        }
                        .padding(16)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("추천 병원")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("새로고침") {
                    hospitalFinder.refreshNearbyHospitals()
                }
                .foregroundStyle(palette.primary)
            }
        }
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }
        return "\(Int(distance))m"
    }
}

private struct DogDetailSheet: View {
    let dog: DogProfile

    var body: some View {
        let palette = dog.theme.palette

        ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dogPhoto(palette: palette)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(dog.name)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(palette.textPrimary)

                        dogInfoRow(title: "견종", value: dog.breed, systemImage: "pawprint.fill", palette: palette)
                        dogInfoRow(title: "나이", value: dog.age, systemImage: "calendar", palette: palette)
                        dogInfoRow(title: "몸무게", value: dog.weight, systemImage: "scalemass", palette: palette)
                        dogInfoRow(title: "대표 색상", value: dog.theme.displayName, systemImage: "paintpalette.fill", palette: palette)
                    }
                    .padding(16)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(20)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("강아지 정보")
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dogPhoto(palette: AppPalette) -> some View {
        if let dataImage = dogDataURIImage() {
            Image(uiImage: dataImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else if let imageURL = dog.imageURL, let url = URL(string: imageURL) {
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
                        .frame(height: 230)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                @unknown default:
                    fallbackDogPhoto(palette: palette)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            fallbackDogPhoto(palette: palette)
        }
    }

    private func fallbackDogPhoto(palette: AppPalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardBackground)
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 70, weight: .semibold))
                .foregroundStyle(palette.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
    }

    private func dogInfoRow(title: String, value: String, systemImage: String, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.primary)
                .frame(width: 34, height: 34)
                .background(palette.secondary.opacity(0.14), in: Circle())

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func dogDataURIImage() -> UIImage? {
        guard let imageURL = dog.imageURL,
              let data = dataFromDataURI(imageURL) else {
            return nil
        }
        return UIImage(data: data)
    }

    private func dataFromDataURI(_ value: String) -> Data? {
        guard value.hasPrefix("data:"),
              let commaIndex = value.firstIndex(of: ",") else {
            return nil
        }

        let metadata = value[..<commaIndex]
        let payload = value[value.index(after: commaIndex)...]
        guard metadata.contains(";base64") else { return nil }
        return Data(base64Encoded: String(payload))
    }
}
