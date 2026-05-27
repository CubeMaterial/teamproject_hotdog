import Combine
import CryptoKit
import LocalAuthentication
import SwiftUI

enum ReviewListMode {
    case all
    case mine
}

@MainActor
final class AppState: ObservableObject {
    private struct UserSession: Codable {
        let userSeq: Int
        let userName: String?
        let userID: String
        let userPhone: String?
        let quickPinHash: String?
    }

    private enum SessionStorage {
        static let key = "hotdog_user_session"
        static let guestCartKey = "hotdog_cart_guest_product_seqs"
        static let guestFavoritesKey = "hotdog_favorite_guest_product_seqs"
        static let guestReadNotificationsKey = "hotdog_read_notifications_guest"

        static func dogOnboardingKey(for userSeq: Int) -> String {
            "hotdog_dog_onboarding_pending_\(userSeq)"
        }

        static func cartKey(for userSeq: Int) -> String {
            "hotdog_cart_product_seqs_\(userSeq)"
        }

        static func favoritesKey(for userSeq: Int) -> String {
            "hotdog_favorite_product_seqs_\(userSeq)"
        }

        static func readNotificationsKey(for userSeq: Int) -> String {
            "hotdog_read_notifications_\(userSeq)"
        }

        static func selectedDogKey(for userSeq: Int) -> String {
            "hotdog_selected_dog_seq_\(userSeq)"
        }
    }

    @Published var isLoggedIn = false
    @Published var isSessionLocked = false
    @Published var isAuthenticating = false
    @Published var authErrorMessage: String? {
        didSet { showErrorSnackbarIfNeeded(authErrorMessage) }
    }
    @Published var signUpErrorMessage: String? {
        didSet { showErrorSnackbarIfNeeded(signUpErrorMessage) }
    }
    @Published var isSigningUp = false
    @Published var needsDogOnboarding = false
    @Published var shouldRequireQuickPinSetup = false
    @Published var currentUserSeq: Int?
    @Published var currentUserName: String?
    @Published var currentUserID: String?
    @Published var currentUserPhone: String?
    @Published var currentUserQuickPinHash: String?
    @Published var selectedTab: AppTab = .home
    @Published var showChatbot = false
    @Published var showCart = false
    @Published var showPayment = false
    @Published var showFavoriteList = false
    @Published var showPurchaseHistory = false
    @Published var showReviewList = false
    @Published var reviewListMode: ReviewListMode = .all
    @Published var showReviewComposer = false
    @Published var selectedProduct: Product?
    @Published var selectedReview: HotdogReview?
    @Published var reviewDraftProductName = ""
    @Published var reviewDraftBuySeq: Int?
    @Published var editingReview: HotdogReview?
    @Published var selectedTheme: DogColorTheme = .brown
    @Published var selectedDog: DogProfile
    @Published var homeSearchText = ""
    @Published var productSearchText = ""
    @Published var selectedProductCategory = "전체"
    @Published var products: [Product]
    @Published var reviews: [HotdogReview]
    @Published var dogs: [DogProfile]
    @Published var notifications: [AppNotificationItem]
    @Published var chatbotOptions: [ChatbotOption]
    @Published var chatbotOptionLabels: [String]
    @Published var favoriteProductIDs: Set<Product.ID> = []
    @Published var cartProductIDs: [Product.ID] = []
    @Published var purchasedProductIDs: [Product.ID] = []
    @Published var purchasedProductSeqs: Set<Int> = []
    @Published var purchaseHistoryItems: [PurchaseHistoryItem] = []
    @Published var checkoutItems: [CartItem] = []
    @Published var savedAddresses: [SavedAddress] = []
    @Published var isLoadingAddresses = false
    @Published var isProcessingPayment = false
    @Published var likedReviewKeys: Set<String> = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var isSendingChatMessage = false
    @Published var isLoadingChatbotOptions = false
    @Published var isLoadingRemoteData = false
    @Published var isSavingDogProfile = false
    @Published var snackbarMessage: String?
    @Published var snackbarIsError = false
    @Published var apiErrorMessage: String? {
        didSet { showErrorSnackbarIfNeeded(apiErrorMessage) }
    }
    @Published var dogOnboardingErrorMessage: String? {
        didSet { showErrorSnackbarIfNeeded(dogOnboardingErrorMessage) }
    }

    private let apiClient = HotdogAPIClient()
    private var snackbarDismissTask: Task<Void, Never>?
    private var chatbotSessionID: String?

    init() {
        let defaultDog = DogProfile(name: "반려견", breed: "정보 없음", age: "-", weight: "-", theme: .brown)

        self.dogs = [defaultDog]
        self.selectedDog = defaultDog
        self.selectedTheme = defaultDog.theme
        self.products = []
        self.reviews = []
        self.notifications = []
        self.chatbotOptions = [
            ChatbotOption(title: "강아지 정보 상담", subtitle: "건강, 행동, 생활 습관을 바로 질문", systemImage: "stethoscope"),
            ChatbotOption(title: "사료 추천", subtitle: "견종과 연령에 맞는 식단 가이드", systemImage: "leaf.fill"),
            ChatbotOption(title: "옷 사이즈 추천", subtitle: "체형에 맞는 사이즈를 빠르게 확인", systemImage: "tshirt.fill"),
            ChatbotOption(title: "간식 추천", subtitle: "알레르기와 취향을 반영한 간식 추천", systemImage: "birthday.cake.fill"),
            ChatbotOption(title: "장난감 추천", subtitle: "에너지 레벨에 맞는 놀이 선택", systemImage: "soccerball")
        ]
        self.chatbotOptionLabels = ["제품", "문의"]
        self.chatMessages = [
            ChatMessage(sender: "HOTDOG", text: "\(defaultDog.name) 기준으로 상담을 시작할 준비가 되었어요.")
        ]
        restoreSession()

        Task {
            await loadRemoteData()
        }
    }

    var palette: AppPalette {
        selectedTheme.palette
    }

    var currentUserDisplayName: String {
        if let name = currentUserName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        if let id = currentUserID?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        return "게스트"
    }

    var hasQuickPin: Bool {
        currentUserQuickPinHash?.isEmpty == false || AuthCredentialStore.loadQuickPin() != nil
    }

    var biometricLoginTitle: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID로 로그인"
        case .touchID:
            return "지문으로 로그인"
        default:
            return "생체인증 로그인"
        }
    }

    func beginDogOnboarding() {
        needsDogOnboarding = true
    }

    func cancelDogOnboardingIfPossible() {
        guard dogs.contains(where: { $0.dbSeq != nil || $0.breed != "정보 없음" }) else { return }
        needsDogOnboarding = false
        dogOnboardingErrorMessage = nil
    }

    func applyTheme(for dog: DogProfile) {
        selectedDog = dog
        selectedTheme = dog.theme
        saveSelectedDogPreference(dog)
        chatMessages = [
            ChatMessage(sender: "HOTDOG", text: "\(dog.name)의 프로필로 상담 대상을 변경했어요.")
        ]
    }

    var filteredHomeProducts: [Product] {
        filteredProducts(searchText: homeSearchText, category: selectedProductCategory)
    }

    var filteredCatalogProducts: [Product] {
        filteredProducts(searchText: productSearchText, category: selectedProductCategory)
    }

    var sortedReviews: [HotdogReview] {
        sorted(reviews: reviews)
    }

    var myReviews: [HotdogReview] {
        sorted(reviews: reviews.filter { isCurrentUserAuthor(of: $0) })
    }

    var hotdogReviewerName: String? {
        sortedReviews.first(where: { $0.likes > 0 })?.author
    }

    var unreadNotificationCount: Int {
        notifications.filter(\.isNew).count
    }

    var favoriteCount: Int {
        favoriteProductIDs.count
    }

    var favoriteProducts: [Product] {
        products.filter { favoriteProductIDs.contains($0.id) }
    }

    var cartCount: Int {
        cartProductIDs.count
    }

    var purchaseCount: Int {
        max(purchasedProductIDs.count, purchasedProductSeqs.count)
    }

    var cartItems: [CartItem] {
        let grouped = Dictionary(grouping: cartProductIDs, by: { $0 })
        return products.compactMap { product in
            guard let ids = grouped[product.id] else { return nil }
            return CartItem(id: product.id, product: product, quantity: ids.count)
        }
    }

    var cartTotalPrice: Int {
        cartItems.reduce(0) { $0 + ($1.product.price * $1.quantity) }
    }

    var checkoutTotalPrice: Int {
        checkoutItems.reduce(0) { $0 + ($1.product.price * $1.quantity) }
    }

    func setProductCategory(_ category: String) {
        selectedProductCategory = category
    }

    func toggleFavorite(for product: Product) {
        if favoriteProductIDs.contains(product.id) {
            favoriteProductIDs.remove(product.id)
        } else {
            favoriteProductIDs.insert(product.id)
        }
        saveFavoritesToLocalStorage()
    }

    func addToCart(_ product: Product, quantity: Int = 1, showsSnackbar: Bool = true) {
        guard !product.isSoldOut else { return }
        let safeQuantity = max(1, quantity)
        cartProductIDs.append(contentsOf: Array(repeating: product.id, count: safeQuantity))
        saveCartToLocalStorage()
        if showsSnackbar {
            showSnackbar("\(product.name) \(safeQuantity)개를 장바구니에 담았어요.")
        }
    }

    func increaseCartQuantity(for product: Product) {
        addToCart(product, showsSnackbar: false)
    }

    func decreaseCartQuantity(for product: Product) {
        removeFromCart(product)
    }

    func presentProductDetail(_ product: Product) {
        selectedProduct = product
    }

    func presentReviewList(mode: ReviewListMode = .all) {
        reviewListMode = mode
        showReviewList = true
        if mode == .mine {
            Task { await loadPurchaseHistory() }
        }
    }

    func presentFavoriteList() {
        showFavoriteList = true
    }

    func presentPurchaseHistory() {
        showPurchaseHistory = true
        Task { await loadPurchaseHistory() }
    }

    func presentReviewComposer() {
        editingReview = nil
        presentReviewComposerAfterDismissingCurrentSheet()
    }

    func presentReviewEditor(for review: HotdogReview) {
        guard isCurrentUserAuthor(of: review) else {
            apiErrorMessage = "내가 작성한 후기만 수정할 수 있습니다."
            return
        }
        editingReview = review
        presentReviewComposerAfterDismissingCurrentSheet()
    }

    func presentReviewComposer(for product: Product) {
        guard canReview(product) else {
            apiErrorMessage = "구매한 상품만 후기를 작성할 수 있습니다."
            return
        }
        reviewDraftBuySeq = reviewablePurchaseItems.first { item in
            item.productSeq == product.dbSeq
        }?.dbSeq
        guard reviewDraftBuySeq != nil else {
            apiErrorMessage = "이미 해당 구매건의 후기를 작성했습니다."
            return
        }
        editingReview = nil
        reviewDraftProductName = product.name
        presentReviewComposerAfterDismissingCurrentSheet()
    }

    func presentReviewComposer(for purchase: PurchaseHistoryItem) {
        guard !purchase.hasReview else {
            apiErrorMessage = "이미 해당 구매건의 후기를 작성했습니다."
            return
        }
        guard purchase.status.canReview else {
            apiErrorMessage = "배송 완료 후 후기를 작성할 수 있습니다."
            return
        }
        guard let product = purchase.product else {
            apiErrorMessage = "리뷰 작성에 필요한 상품 정보가 없습니다."
            return
        }
        editingReview = nil
        reviewDraftBuySeq = purchase.dbSeq
        reviewDraftProductName = product.name
        presentReviewComposerAfterDismissingCurrentSheet()
    }

    private func presentReviewComposerAfterDismissingCurrentSheet() {
        let needsDelay = dismissPresentedSheetIfNeeded()
        guard needsDelay else {
            showReviewComposer = true
            return
        }

        Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            showReviewComposer = true
        }
    }

    private func dismissPresentedSheetIfNeeded() -> Bool {
        let hasPresentedSheet = showChatbot ||
            showCart ||
            showPayment ||
            showFavoriteList ||
            showPurchaseHistory ||
            showReviewList ||
            selectedProduct != nil ||
            selectedReview != nil

        guard hasPresentedSheet else { return false }

        showChatbot = false
        showCart = false
        showPayment = false
        showFavoriteList = false
        showPurchaseHistory = false
        showReviewList = false
        selectedProduct = nil
        selectedReview = nil
        return true
    }

    func presentReviewDetail(_ review: HotdogReview) {
        selectedReview = review
    }

    func removeFromCart(_ product: Product) {
        guard let index = cartProductIDs.firstIndex(of: product.id) else { return }
        cartProductIDs.remove(at: index)
        saveCartToLocalStorage()
    }

    func clearCart() {
        cartProductIDs.removeAll()
        saveCartToLocalStorage()
    }

    func showSnackbar(_ message: String, isError: Bool = false) {
        snackbarDismissTask?.cancel()
        snackbarMessage = message
        snackbarIsError = isError
        snackbarDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.snackbarMessage = nil
                self?.snackbarIsError = false
            }
        }
    }

    private func showErrorSnackbarIfNeeded(_ message: String?) {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        showSnackbar(message, isError: true)
    }

    func startCheckout(for product: Product, quantity: Int = 1) {
        guard !product.isSoldOut else { return }
        let safeQuantity = min(max(1, quantity), max(1, product.stockQuantity))
        checkoutItems = [CartItem(id: product.id, product: product, quantity: safeQuantity)]
        showPayment = true
        Task { await loadSavedAddresses() }
    }

    func startCartCheckout() {
        guard !cartItems.isEmpty else { return }
        checkoutItems = cartItems
        showCart = false
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            await loadSavedAddresses()
            showPayment = true
        }
    }

    @discardableResult
    func completePayment(address: String, paymentMethod: String) async -> Bool {
        guard let currentUserSeq else {
            apiErrorMessage = "결제하려면 먼저 로그인해주세요."
            return false
        }
        guard !checkoutItems.isEmpty else {
            apiErrorMessage = "결제할 상품이 없습니다."
            return false
        }

        isProcessingPayment = true
        defer { isProcessingPayment = false }

        let requests = checkoutItems.compactMap { item -> CreatePurchaseItemRequest? in
            guard let productSeq = item.product.dbSeq else { return nil }
            return CreatePurchaseItemRequest(
                productSeq: productSeq,
                quantity: item.quantity,
                price: item.product.price
            )
        }

        guard requests.count == checkoutItems.count else {
            apiErrorMessage = "결제 저장에 필요한 상품 정보가 없습니다."
            return false
        }

        do {
            let purchasedSeqs = try await apiClient.createPurchases(
                userSeq: currentUserSeq,
                items: requests,
                address: address,
                paymentMethod: paymentMethod
            )
            purchasedProductSeqs.formUnion(purchasedSeqs)
            purchasedProductIDs.append(contentsOf: checkoutItems.map(\.product.id))
            await loadPurchaseHistory()
            checkoutItems.forEach { item in
                cartProductIDs.removeAll { $0 == item.product.id }
            }
            saveCartToLocalStorage()
            notifications.insert(
                AppNotificationItem(
                    category: "주문",
                    title: "\(checkoutItems.count)개 상품 결제가 완료됐어요",
                    detail: "\(selectedDog.name) 맞춤 상품이 구매 내역에 추가됐어요",
                    isNew: true
                ),
                at: 0
            )
            checkoutItems = []
            await loadSavedAddresses()
            showPayment = false
            showCart = false
            selectedProduct = nil
            selectedTab = .home
            apiErrorMessage = nil
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    func canReview(_ product: Product) -> Bool {
        guard let productSeq = product.dbSeq else { return false }
        return reviewablePurchaseItems.contains { $0.productSeq == productSeq }
    }

    var reviewablePurchaseItems: [PurchaseHistoryItem] {
        purchaseHistoryItems.filter { item in
            item.status.canReview && !item.hasReview && item.product != nil
        }
    }

    var purchasedReviewProducts: [Product] {
        let reviewableSeqs = Set(reviewablePurchaseItems.compactMap(\.productSeq))
        return products.filter { product in
            guard let productSeq = product.dbSeq else { return false }
            return reviewableSeqs.contains(productSeq)
        }
    }

    func buyNow(_ product: Product) {
        startCheckout(for: product)
    }

    private func recordLocalPurchase(_ product: Product) {
        guard !product.isSoldOut else { return }

        purchasedProductIDs.append(product.id)
        if let productSeq = product.dbSeq {
            purchasedProductSeqs.insert(productSeq)
        }
        notifications.insert(
            AppNotificationItem(
                category: "주문",
                title: "\(product.name) 주문이 완료됐어요",
                detail: "\(selectedDog.name) 맞춤 상품으로 주문 내역에 추가됐어요",
                isNew: true
            ),
            at: 0
        )
        selectedTab = .myPage
    }

    func canEditReview(_ review: HotdogReview) -> Bool {
        isCurrentUserAuthor(of: review)
    }

    func canLikeReview(_ review: HotdogReview) -> Bool {
        !likedReviewKeys.contains(reviewLikeKey(for: review))
    }

    func toggleReviewLike(for review: HotdogReview) {
        guard canLikeReview(review),
              let index = reviews.firstIndex(where: { sameReview($0, review) }) else { return }
        let key = reviewLikeKey(for: review)
        reviews[index].likes += 1
        likedReviewKeys.insert(key)

        guard let reviewSeq = review.dbSeq else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let updated = try await apiClient.likeReview(reviewSeq: reviewSeq)
                let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
                    if let dbSeq = product.dbSeq {
                        result[dbSeq] = product
                    }
                }
                let updatedReview = updated.toModel(productsBySeq: productsBySeq)
                if let updatedIndex = self.reviews.firstIndex(where: { self.sameReview($0, updatedReview) }) {
                    self.reviews[updatedIndex] = self.reviewPreservingIdentity(
                        current: self.reviews[updatedIndex],
                        updated: updatedReview
                    )
                }
            } catch {
                if let currentIndex = self.reviews.firstIndex(where: { self.sameReview($0, review) }) {
                    self.reviews[currentIndex].likes = max(0, self.reviews[currentIndex].likes - 1)
                }
                self.likedReviewKeys.remove(key)
                self.apiErrorMessage = error.localizedDescription
            }
        }
    }

    private func reviewPreservingIdentity(current: HotdogReview, updated: HotdogReview) -> HotdogReview {
        HotdogReview(
            id: current.id,
            dbSeq: updated.dbSeq,
            title: updated.title,
            author: updated.author,
            breed: updated.breed,
            productName: updated.productName,
            summary: updated.summary,
            body: updated.body,
            rating: updated.rating,
            dateText: updated.dateText,
            likes: updated.likes,
            productSeq: updated.productSeq,
            userSeq: updated.userSeq,
            reviewImageURL: updated.reviewImageURL
        )
    }

    func loadRemoteData() async {
        isLoadingRemoteData = true
        defer { isLoadingRemoteData = false }

        do {
            let fetchedProducts = try await apiClient.fetchProducts()
            let productsBySeq = fetchedProducts.reduce(into: [Int: Product]()) { result, product in
                if let dbSeq = product.dbSeq {
                    result[dbSeq] = product
                }
            }
            let fetchedReviews = try await apiClient.fetchReviews(productsBySeq: productsBySeq)

            if !fetchedProducts.isEmpty {
                products = fetchedProducts
                restoreCartFromLocalStorage()
                restoreFavoritesFromLocalStorage()
            }
            if !fetchedReviews.isEmpty {
                reviews = fetchedReviews
            }

            if let currentUserSeq {
                if let profile = try? await apiClient.fetchUserProfile(userSeq: currentUserSeq) {
                    currentUserName = profile.userName
                    currentUserID = profile.userID ?? currentUserID
                    currentUserPhone = profile.userPhone
                    currentUserQuickPinHash = profile.quickPinHash
                    if let currentUserID {
                        saveSession(
                            userSeq: currentUserSeq,
                            userName: currentUserName,
                            userID: currentUserID,
                            userPhone: currentUserPhone,
                            quickPinHash: currentUserQuickPinHash
                        )
                    }
                }

                let fetchedDogs = try await apiClient.fetchUserDogs(userSeq: currentUserSeq)
                dogs = fetchedDogs
                if !fetchedDogs.isEmpty {
                    applyPreferredSelectedDog(from: fetchedDogs, userSeq: currentUserSeq)
                }

                let fetchedNotifications = try await apiClient.fetchUserNotifications(userSeq: currentUserSeq)
                if !fetchedNotifications.isEmpty {
                    notifications = applyReadState(to: fetchedNotifications)
                }

                let purchasedSeqs = try await apiClient.fetchUserPurchasedProductSeqs(userSeq: currentUserSeq)
                purchasedProductSeqs = Set(purchasedSeqs)
                purchaseHistoryItems = try await apiClient.fetchUserPurchases(
                    userSeq: currentUserSeq,
                    productsBySeq: productsBySeq
                )

                savedAddresses = try await apiClient.fetchUserAddresses(userSeq: currentUserSeq)
            }
            apiErrorMessage = nil
        } catch {
            apiErrorMessage = error.localizedDescription
        }
    }

    func loadSavedAddresses() async {
        guard let currentUserSeq else {
            savedAddresses = []
            return
        }

        isLoadingAddresses = true
        defer { isLoadingAddresses = false }

        do {
            savedAddresses = try await apiClient.fetchUserAddresses(userSeq: currentUserSeq)
            apiErrorMessage = nil
        } catch {
            apiErrorMessage = error.localizedDescription
        }
    }

    func loadPurchaseHistory() async {
        guard let currentUserSeq else {
            purchaseHistoryItems = []
            purchasedProductSeqs = []
            return
        }

        do {
            let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
                if let dbSeq = product.dbSeq {
                    result[dbSeq] = product
                }
            }
            let history = try await apiClient.fetchUserPurchases(userSeq: currentUserSeq, productsBySeq: productsBySeq)
            purchaseHistoryItems = history
            purchasedProductSeqs = Set(history.compactMap { item in
                item.status.canReview ? item.productSeq : nil
            })
            apiErrorMessage = nil
        } catch {
            apiErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func updatePurchaseStatus(_ purchase: PurchaseHistoryItem, action: String) async -> Bool {
        guard let currentUserSeq, let buySeq = purchase.dbSeq else {
            apiErrorMessage = "주문 상태를 변경할 수 없습니다."
            return false
        }

        do {
            try await apiClient.updatePurchaseStatus(userSeq: currentUserSeq, buySeq: buySeq, action: action)
            applyPurchaseStatusLocally(buySeq: buySeq, action: action)
            let message: String
            switch action {
            case "cancel":
                message = "주문이 취소되었습니다."
            case "receive":
                message = "수령 완료로 변경되었습니다."
            case "confirm":
                message = "구매가 확정되었습니다."
            case "refund":
                message = "환불 요청이 접수되었습니다."
            default:
                message = "주문 상태가 변경되었습니다."
            }
            apiErrorMessage = nil
            showSnackbar(message)
            await loadPurchaseHistory()
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    private func applyPurchaseStatusLocally(buySeq: Int, action: String) {
        let nextStatus: PurchaseStatus?
        switch action {
        case "cancel":
            nextStatus = .canceled
        case "receive", "deliver":
            nextStatus = .delivered
        case "confirm":
            nextStatus = .confirmed
        case "refund":
            nextStatus = .refundRequested
        default:
            nextStatus = nil
        }

        guard let nextStatus else { return }
        purchaseHistoryItems = purchaseHistoryItems.map { item in
            guard item.dbSeq == buySeq else { return item }
            return PurchaseHistoryItem(
                dbSeq: item.dbSeq,
                product: item.product,
                productSeq: item.productSeq,
                quantity: item.quantity,
                totalPrice: item.totalPrice,
                dateText: item.dateText,
                hasReview: item.hasReview,
                status: nextStatus
            )
        }
        purchasedProductSeqs = Set(purchaseHistoryItems.compactMap { item in
            item.status.canReview ? item.productSeq : nil
        })
    }

    @discardableResult
    func login(userID: String, password: String) async -> Bool {
        let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, !password.isEmpty else {
            authErrorMessage = "아이디와 비밀번호를 입력해주세요."
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let user = try await apiClient.login(userID: trimmedID, userPW: password)
            currentUserSeq = user.userSeq
            currentUserName = user.userName
            currentUserID = user.userID ?? trimmedID
            currentUserPhone = user.userPhone
            currentUserQuickPinHash = user.quickPinHash
            restoreCartFromLocalStorage()
            restoreFavoritesFromLocalStorage()
            needsDogOnboarding = isDogOnboardingPending(for: user.userSeq)
            isLoggedIn = true
            isSessionLocked = false
            if hasQuickPin {
                shouldRequireQuickPinSetup = false
            } else {
                shouldRequireQuickPinSetup = true
                isSessionLocked = true
            }
            saveSession(
                userSeq: user.userSeq,
                userName: user.userName,
                userID: user.userID ?? trimmedID,
                userPhone: user.userPhone,
                quickPinHash: user.quickPinHash
            )
            AuthCredentialStore.save(email: trimmedID, password: password)
            authErrorMessage = nil
            apiErrorMessage = nil
            await loadRemoteData()
            return true
        } catch {
            authErrorMessage = error.localizedDescription
            isLoggedIn = false
            return false
        }
    }

    func logout() {
        isLoggedIn = false
        isSessionLocked = false
        currentUserSeq = nil
        currentUserName = nil
        currentUserID = nil
        currentUserPhone = nil
        currentUserQuickPinHash = nil
        favoriteProductIDs = []
        cartProductIDs = []
        checkoutItems = []
        needsDogOnboarding = false
        shouldRequireQuickPinSetup = false
        removeSession()
        AuthCredentialStore.clear()
    }

    @discardableResult
    func unlockWithQuickPin(_ pin: String) -> Bool {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            authErrorMessage = "간편 비밀번호 4자리를 입력해주세요."
            return false
        }

        let pinHash = quickPinHash(for: pin)
        let matchesDatabasePin = currentUserQuickPinHash == pinHash
        let matchesLocalPin = AuthCredentialStore.loadQuickPin() == pin
        guard matchesDatabasePin || matchesLocalPin else {
            authErrorMessage = "간편 비밀번호가 일치하지 않습니다."
            return false
        }

        if matchesDatabasePin && !matchesLocalPin {
            AuthCredentialStore.saveQuickPin(pin)
        }
        isSessionLocked = false
        shouldRequireQuickPinSetup = false
        authErrorMessage = nil
        return true
    }

    @discardableResult
    func setQuickPin(_ pin: String) async -> Bool {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            authErrorMessage = "간편 비밀번호는 숫자 4자리여야 합니다."
            return false
        }
        guard let currentUserSeq else {
            authErrorMessage = "로그인한 사용자 정보가 없습니다."
            return false
        }

        let pinHash = quickPinHash(for: pin)
        do {
            try await apiClient.updateUserQuickPin(userSeq: currentUserSeq, quickPinHash: pinHash)
            saveQuickPinState(pin: pin, pinHash: pinHash)
            return true
        } catch {
            authErrorMessage = "간편 비밀번호를 DB에 저장하지 못했습니다: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func resetQuickPin(accountPassword: String, newPin: String) async -> Bool {
        guard newPin.count == 4, newPin.allSatisfy(\.isNumber) else {
            authErrorMessage = "새 간편 비밀번호는 숫자 4자리여야 합니다."
            return false
        }
        guard let currentUserSeq, let currentUserID else {
            authErrorMessage = "로그인한 사용자 정보가 없습니다."
            return false
        }
        guard !accountPassword.isEmpty else {
            authErrorMessage = "계정 비밀번호를 입력해주세요."
            return false
        }

        do {
            let user = try await apiClient.login(userID: currentUserID, userPW: accountPassword)
            guard user.userSeq == currentUserSeq else {
                authErrorMessage = "현재 로그인된 계정과 일치하지 않습니다."
                return false
            }

            let pinHash = quickPinHash(for: newPin)
            try await apiClient.updateUserQuickPin(userSeq: currentUserSeq, quickPinHash: pinHash)
            currentUserName = user.userName ?? currentUserName
            currentUserPhone = user.userPhone ?? currentUserPhone
            AuthCredentialStore.save(email: currentUserID, password: accountPassword)
            saveQuickPinState(pin: newPin, pinHash: pinHash)
            return true
        } catch {
            authErrorMessage = "계정 비밀번호 확인에 실패했습니다: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func loginWithBiometrics() async -> Bool {
        guard let credential = AuthCredentialStore.load() else {
            authErrorMessage = "먼저 이메일/비밀번호로 1회 로그인해주세요."
            return false
        }

        let context = LAContext()
        var evaluateError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluateError) else {
            authErrorMessage = "생체인증을 사용할 수 없습니다."
            return false
        }

        do {
            let success = try await evaluateBiometric(context: context)
            guard success else {
                authErrorMessage = "생체인증 로그인에 실패했습니다."
                return false
            }
            if isLoggedIn && isSessionLocked {
                isSessionLocked = false
                authErrorMessage = nil
                return true
            }
            return await login(userID: credential.email, password: credential.password)
        } catch {
            authErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func signUp(
        userID: String,
        password: String,
        userName: String,
        userPhone: String
    ) async -> Bool {
        let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = userPhone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedID) else {
            signUpErrorMessage = "아이디는 이메일 형식이어야 합니다."
            return false
        }
        guard !trimmedID.isEmpty, !trimmedPassword.isEmpty, !trimmedName.isEmpty else {
            signUpErrorMessage = "아이디, 비밀번호, 이름을 입력해주세요."
            return false
        }
        guard isValidPassword(trimmedPassword) else {
            signUpErrorMessage = "비밀번호는 8자 이상, 영문 포함이어야 합니다."
            return false
        }

        isSigningUp = true
        defer { isSigningUp = false }

        do {
            let user = try await apiClient.signUp(
                userID: trimmedID,
                userPW: trimmedPassword,
                userName: trimmedName,
                userPhone: trimmedPhone.isEmpty ? nil : trimmedPhone
            )
            currentUserSeq = user.userSeq
            currentUserName = user.userName
            currentUserID = user.userID ?? trimmedID
            currentUserPhone = user.userPhone ?? trimmedPhone
            currentUserQuickPinHash = user.quickPinHash
            setDogOnboardingPending(true, for: user.userSeq)
            needsDogOnboarding = true
            isLoggedIn = true
            isSessionLocked = true
            shouldRequireQuickPinSetup = true
            saveSession(
                userSeq: user.userSeq,
                userName: user.userName,
                userID: user.userID ?? trimmedID,
                userPhone: user.userPhone ?? trimmedPhone,
                quickPinHash: user.quickPinHash
            )
            AuthCredentialStore.save(email: trimmedID, password: trimmedPassword)
            signUpErrorMessage = nil
            authErrorMessage = nil
            apiErrorMessage = nil
            await loadRemoteData()
            return true
        } catch {
            signUpErrorMessage = error.localizedDescription
            return false
        }
    }

    func checkUserIDAvailable(_ email: String) async -> (success: Bool, message: String) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmed) else {
            return (false, "올바른 이메일 형식을 입력해주세요.")
        }

        do {
            let response = try await apiClient.checkUserIDAvailability(userID: trimmed)
            if response.isAvailable {
                return (true, response.message ?? "사용 가능한 아이디입니다.")
            }
            return (false, response.message ?? "이미 사용 중인 아이디입니다.")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func findUserID(userName: String, userPhone: String) async -> (success: Bool, userID: String?, message: String) {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = userPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else {
            return (false, nil, "이름과 전화번호를 입력해주세요.")
        }

        do {
            let response = try await apiClient.findUserID(userName: trimmedName, userPhone: trimmedPhone)
            return (true, response.userID, response.message ?? "가입 아이디를 찾았습니다.")
        } catch {
            return (false, nil, error.localizedDescription)
        }
    }

    func resetPassword(userID: String, newPassword: String) async -> (success: Bool, message: String) {
        let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedID) else {
            return (false, "올바른 이메일 형식을 입력해주세요.")
        }
        guard isValidPassword(trimmedPassword) else {
            return (false, "비밀번호는 8자 이상, 영문 포함이어야 합니다.")
        }

        do {
            let response = try await apiClient.resetPassword(userID: trimmedID, userPW: trimmedPassword)
            return (true, response.message ?? "비밀번호가 변경되었습니다.")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func requestEmailVerificationCode(email: String) async -> (success: Bool, message: String) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmed) else {
            return (false, "올바른 이메일 형식을 입력해주세요.")
        }

        do {
            let response = try await apiClient.sendEmailVerificationCode(email: trimmed)
            let message: String
            if let verificationCode = response.verificationCode {
                message = "인증코드: \(verificationCode)"
            } else {
                message = response.message ?? "인증코드를 발급했습니다."
            }
            return (true, message)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func verifyEmailCode(email: String, code: String) async -> (success: Bool, message: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            return (false, "인증코드를 입력해주세요.")
        }

        do {
            let response = try await apiClient.verifyEmailCode(email: trimmedEmail, code: trimmedCode)
            return (true, response.message ?? "이메일 인증이 완료되었습니다.")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func validateReviewText(_ text: String) async -> (isAllowed: Bool, message: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return (true, "")
        }

        do {
            let response = try await apiClient.predictCurse(text: trimmedText)
            if response.isCurse {
                return (false, "후기에 비속어가 포함되어 있습니다. 내용을 수정해주세요.")
            }
            return (true, response.result ?? "정상 문장")
        } catch {
            showSnackbar("비속어 감지 기능이 꺼져 있어 검사를 건너뜁니다.")
            return (true, "비속어 감지 기능이 꺼져 있습니다.")
        }
    }

    @discardableResult
    func addReview(
        title: String,
        productName: String,
        summary: String,
        body: String,
        rating: Int,
        reviewImage: String? = nil
    ) async -> Bool {
        guard let currentUserSeq else {
            apiErrorMessage = "리뷰를 작성하려면 먼저 로그인해주세요."
            return false
        }

        guard let selectedProduct = products.first(where: { $0.name == productName }),
              let productSeq = selectedProduct.dbSeq else {
            apiErrorMessage = "리뷰 저장에 필요한 상품 정보가 없습니다."
            return false
        }
        guard canReview(selectedProduct) else {
            apiErrorMessage = "구매한 상품만 후기를 작성할 수 있습니다."
            return false
        }
        let buySeq = reviewDraftBuySeq ?? purchaseHistoryItems.first { item in
            item.productSeq == productSeq && !item.hasReview
        }?.dbSeq
        guard let buySeq else {
            apiErrorMessage = "이미 해당 구매건의 후기를 작성했습니다."
            return false
        }

        let request = CreateReviewRequest(
            productSeq: productSeq,
            userSeq: currentUserSeq,
            buySeq: buySeq,
            reviewTitle: title,
            reviewContent: body,
            reviewImage: reviewImage,
            reviewRating: rating
        )

        do {
            let created = try await apiClient.createReview(request)
            let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
                if let dbSeq = product.dbSeq {
                    result[dbSeq] = product
                }
            }
            let review = created.toModel(productsBySeq: productsBySeq)
            reviews.insert(review, at: 0)
            notifications.insert(
                AppNotificationItem(
                    category: "리뷰",
                    title: "\(productName) 후기가 등록됐어요",
                    detail: "작성한 후기는 마이페이지와 후기 탭에서 확인할 수 있어요",
                    isNew: true
                ),
                at: 0
            )
            apiErrorMessage = nil
            reviewDraftBuySeq = nil
            reviewDraftProductName = ""
            await loadPurchaseHistory()
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateReview(
        _ review: HotdogReview,
        title: String,
        body: String,
        rating: Int,
        reviewImage: String? = nil
    ) async -> Bool {
        guard let currentUserSeq, let reviewSeq = review.dbSeq else {
            apiErrorMessage = "수정할 후기 정보가 없습니다."
            return false
        }
        guard isCurrentUserAuthor(of: review) else {
            apiErrorMessage = "내가 작성한 후기만 수정할 수 있습니다."
            return false
        }

        let request = UpdateReviewRequest(
            userSeq: currentUserSeq,
            reviewTitle: title,
            reviewContent: body,
            reviewImage: reviewImage,
            reviewRating: rating
        )

        do {
            let updated = try await apiClient.updateReview(reviewSeq: reviewSeq, request: request)
            let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
                if let dbSeq = product.dbSeq {
                    result[dbSeq] = product
                }
            }
            let updatedReview = updated.toModel(productsBySeq: productsBySeq)
            if let index = reviews.firstIndex(where: { sameReview($0, updatedReview) }) {
                reviews[index] = updatedReview
            }
            if let selectedReview, sameReview(selectedReview, updatedReview) {
                self.selectedReview = updatedReview
            }
            editingReview = nil
            apiErrorMessage = nil
            showSnackbar("후기가 수정되었습니다.")
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func deleteReview(_ review: HotdogReview) async -> Bool {
        guard let currentUserSeq, let reviewSeq = review.dbSeq else {
            apiErrorMessage = "삭제할 후기 정보가 없습니다."
            return false
        }
        guard isCurrentUserAuthor(of: review) else {
            apiErrorMessage = "내가 작성한 후기만 삭제할 수 있습니다."
            return false
        }

        do {
            try await apiClient.deleteReview(reviewSeq: reviewSeq, userSeq: currentUserSeq)
            reviews.removeAll { sameReview($0, review) }
            if let selectedReview, sameReview(selectedReview, review) {
                self.selectedReview = nil
            }
            await loadPurchaseHistory()
            apiErrorMessage = nil
            showSnackbar("후기가 삭제되었습니다.")
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    func markNotificationRead(_ notification: AppNotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[index].isNew = false
        saveReadNotificationKey(for: notifications[index])
    }

    func markAllNotificationsRead() {
        notifications.indices.forEach { index in
            notifications[index].isNew = false
            saveReadNotificationKey(for: notifications[index])
        }
    }

    @discardableResult
    func completeDogOnboarding(name: String, breed: String, age: String, weight: String, theme: DogColorTheme, imageDataURI: String? = nil) async -> Bool {
        let newDog = DogProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            age: age.trimmingCharacters(in: .whitespacesAndNewlines),
            weight: weight.trimmingCharacters(in: .whitespacesAndNewlines),
            theme: theme,
            imageURL: imageDataURI
        )

        guard let currentUserSeq else {
            applyCompletedDogOnboarding(newDog)
            dogOnboardingErrorMessage = nil
            return true
        }

        isSavingDogProfile = true
        defer { isSavingDogProfile = false }

        do {
            let request = CreateDogRequest(
                dogName: newDog.name,
                breedName: newDog.breed,
                ageName: newDog.age,
                weightText: newDog.weight,
                colorName: newDog.theme.displayName,
                dogImage: imageDataURI
            )
            let savedDog = try await apiClient.createUserDog(userSeq: currentUserSeq, request: request)
            applyCompletedDogOnboarding(savedDog)
            await refreshUserDogsAfterMutation(userSeq: currentUserSeq, preferredDog: savedDog)
            setDogOnboardingPending(false, for: currentUserSeq)
            dogOnboardingErrorMessage = nil
            apiErrorMessage = nil
            return true
        } catch {
            dogOnboardingErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func deleteDog(_ dog: DogProfile) async -> Bool {
        guard let currentUserSeq else {
            removeDogLocally(dog)
            return true
        }
        guard let dogSeq = dog.dbSeq else {
            removeDogLocally(dog)
            return true
        }

        do {
            try await apiClient.deleteUserDog(userSeq: currentUserSeq, dogSeq: dogSeq)
            removeDogLocally(dog)
            apiErrorMessage = nil
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateDog(_ dog: DogProfile, name: String, breed: String, age: String, weight: String, theme: DogColorTheme) async -> Bool {
        let updatedDog = DogProfile(
            id: dog.id,
            dbSeq: dog.dbSeq,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            age: age.trimmingCharacters(in: .whitespacesAndNewlines),
            weight: weight.trimmingCharacters(in: .whitespacesAndNewlines),
            theme: theme,
            imageURL: dog.imageURL
        )

        guard let currentUserSeq, let dogSeq = dog.dbSeq else {
            applyCompletedDogOnboarding(updatedDog)
            showSnackbar("강아지 정보가 수정되었습니다.")
            return true
        }

        isSavingDogProfile = true
        defer { isSavingDogProfile = false }

        do {
            let request = CreateDogRequest(
                dogName: updatedDog.name,
                breedName: updatedDog.breed,
                ageName: updatedDog.age,
                weightText: updatedDog.weight,
                colorName: updatedDog.theme.displayName,
                dogImage: nil
            )
            let savedDog = try await apiClient.updateUserDog(userSeq: currentUserSeq, dogSeq: dogSeq, request: request)
            applyCompletedDogOnboarding(savedDog)
            await refreshUserDogsAfterMutation(userSeq: currentUserSeq, preferredDog: savedDog)
            apiErrorMessage = nil
            showSnackbar("강아지 정보가 수정되었습니다.")
            return true
        } catch {
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    private func applyCompletedDogOnboarding(_ dog: DogProfile) {
        if let index = dogs.firstIndex(where: { sameDog($0, dog) }) {
            dogs[index] = dog
        } else {
            if dogs.count == 1, dogs[0].dbSeq == nil, dogs[0].breed == "정보 없음" {
                dogs = [dog]
            } else {
                dogs.append(dog)
            }
        }
        selectedDog = dog
        selectedTheme = dog.theme
        saveSelectedDogPreference(dog)
        chatMessages = [
            ChatMessage(sender: "HOTDOG", text: "\(dog.name) 프로필 등록이 완료됐어요.")
        ]
        needsDogOnboarding = false
    }

    private func refreshUserDogsAfterMutation(userSeq: Int, preferredDog: DogProfile?) async {
        do {
            let fetchedDogs = try await apiClient.fetchUserDogs(userSeq: userSeq)
            dogs = fetchedDogs
            if let preferredDog,
               let refreshedDog = fetchedDogs.first(where: { sameDog($0, preferredDog) }) {
                selectedDog = refreshedDog
                selectedTheme = refreshedDog.theme
                saveSelectedDogPreference(refreshedDog)
            } else if let firstDog = fetchedDogs.first {
                applyPreferredSelectedDog(from: fetchedDogs, userSeq: userSeq, fallback: firstDog)
            }
        } catch {
            apiErrorMessage = error.localizedDescription
        }
    }

    private func removeDogLocally(_ dog: DogProfile) {
        dogs.removeAll { sameDog($0, dog) }
        if dogs.isEmpty {
            let defaultDog = DogProfile(name: "반려견", breed: "정보 없음", age: "-", weight: "-", theme: .brown)
            dogs = [defaultDog]
            selectedDog = defaultDog
            selectedTheme = defaultDog.theme
            needsDogOnboarding = true
            return
        }

        if sameDog(selectedDog, dog), let firstDog = dogs.first {
            selectedDog = firstDog
            selectedTheme = firstDog.theme
            saveSelectedDogPreference(firstDog)
        }
    }

    private func applyPreferredSelectedDog(from fetchedDogs: [DogProfile], userSeq: Int, fallback: DogProfile? = nil) {
        let preferredSeq = UserDefaults.standard.integer(forKey: SessionStorage.selectedDogKey(for: userSeq))
        if preferredSeq > 0,
           let preferredDog = fetchedDogs.first(where: { $0.dbSeq == preferredSeq }) {
            selectedDog = preferredDog
            selectedTheme = preferredDog.theme
            return
        }

        if fetchedDogs.contains(where: { sameDog($0, selectedDog) }) {
            if let current = fetchedDogs.first(where: { sameDog($0, selectedDog) }) {
                selectedDog = current
                selectedTheme = current.theme
            }
            return
        }

        if let fallback {
            selectedDog = fallback
            selectedTheme = fallback.theme
        } else if let firstDog = fetchedDogs.first {
            selectedDog = firstDog
            selectedTheme = firstDog.theme
        }
        saveSelectedDogPreference(selectedDog)
    }

    private func saveSelectedDogPreference(_ dog: DogProfile) {
        guard let currentUserSeq, let dogSeq = dog.dbSeq else { return }
        UserDefaults.standard.set(dogSeq, forKey: SessionStorage.selectedDogKey(for: currentUserSeq))
    }

    private func sameDog(_ lhs: DogProfile, _ rhs: DogProfile) -> Bool {
        if let lhsSeq = lhs.dbSeq, let rhsSeq = rhs.dbSeq {
            return lhsSeq == rhsSeq
        }
        return lhs.id == rhs.id
    }

    private func sorted(reviews: [HotdogReview]) -> [HotdogReview] {
        reviews.sorted {
            if $0.likes != $1.likes {
                return $0.likes > $1.likes
            }
            return ($0.dbSeq ?? 0) > ($1.dbSeq ?? 0)
        }
    }

    private func sameReview(_ lhs: HotdogReview, _ rhs: HotdogReview) -> Bool {
        if let lhsSeq = lhs.dbSeq, let rhsSeq = rhs.dbSeq {
            return lhsSeq == rhsSeq
        }
        return lhs.id == rhs.id
    }

    private func reviewLikeKey(for review: HotdogReview) -> String {
        if let dbSeq = review.dbSeq {
            return "db:\(dbSeq)"
        }
        return "local:\(review.id.uuidString)"
    }

    private func isCurrentUserAuthor(of review: HotdogReview) -> Bool {
        if let userSeq = review.userSeq, let currentUserSeq {
            return userSeq == currentUserSeq
        }
        return false
    }

    func loadChatbotOptions() async {
        guard !isLoadingChatbotOptions else { return }

        isLoadingChatbotOptions = true
        defer { isLoadingChatbotOptions = false }

        do {
            let response = try await apiClient.fetchChatbotOptions()
            let options = sanitizedChatbotOptions(response.resolvedOptions)
            if !options.isEmpty {
                chatbotOptionLabels = options
            }
        } catch {
            if chatbotOptionLabels.isEmpty {
                chatbotOptionLabels = ["제품", "문의"]
            }
        }
    }

    @discardableResult
    func selectChatbotOption(_ selected: String) async -> Bool {
        let trimmedSelection = selected.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSelection.isEmpty, !isSendingChatMessage else { return false }

        chatMessages.append(ChatMessage(sender: "나", text: trimmedSelection))
        isSendingChatMessage = true
        defer { isSendingChatMessage = false }

        do {
            let response = try await apiClient.selectChatbotOption(trimmedSelection)
            let answer = response.resolvedAnswer?.trimmingCharacters(in: .whitespacesAndNewlines)
            chatMessages.append(ChatMessage(sender: "HOTDOG", text: answer?.isEmpty == false ? answer! : "답변을 받지 못했습니다."))

            let options = sanitizedChatbotOptions(response.resolvedOptions)
            if !options.isEmpty {
                chatbotOptionLabels = options
            }

            apiErrorMessage = nil
            return true
        } catch {
            let fallback = "챗봇 서버와 연결하지 못했습니다. hot_dog_chatbot FastAPI/Ollama 서버가 실행 중인지 확인해주세요."
            chatMessages.append(ChatMessage(sender: "HOTDOG", text: fallback))
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func askChatbot(question: String) async -> Bool {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, !isSendingChatMessage else { return false }

        chatMessages.append(ChatMessage(sender: "나", text: trimmedQuestion))
        isSendingChatMessage = true
        defer { isSendingChatMessage = false }

        do {
            let response = try await apiClient.sendChatMessage(
                message: trimmedQuestion,
                sessionID: chatbotSessionID,
                userSeq: currentUserSeq,
                userID: currentUserID
            )
            chatbotSessionID = response.resolvedSessionID ?? chatbotSessionID
            let answer = response.resolvedAnswer?.trimmingCharacters(in: .whitespacesAndNewlines)
            chatMessages.append(ChatMessage(sender: "HOTDOG", text: answer?.isEmpty == false ? answer! : "답변을 받지 못했습니다."))
            apiErrorMessage = nil
            return true
        } catch {
            let fallback = "챗봇 서버와 연결하지 못했습니다. hot_dog_chatbot FastAPI/Ollama 서버가 실행 중인지 확인해주세요."
            chatMessages.append(ChatMessage(sender: "HOTDOG", text: fallback))
            apiErrorMessage = error.localizedDescription
            return false
        }
    }

    func useChatbotOption(_ option: ChatbotOption) {
        Task {
            await askChatbot(question: option.title)
        }
    }

    func chatbotSheetView() -> some View {
        ChatbotView()
            .environmentObject(self)
    }

    func cartSheetView() -> some View {
        CartView()
            .environmentObject(self)
    }

    func paymentSheetView() -> some View {
        PaymentView()
            .environmentObject(self)
    }

    func favoriteListSheetView() -> some View {
        FavoriteListView()
            .environmentObject(self)
    }

    func purchaseHistorySheetView() -> some View {
        NavigationStack {
            PurchaseHistoryView(showsCloseButton: true)
                .environmentObject(self)
        }
    }

    func productDetailSheet(for product: Product) -> some View {
        ProductDetailView(product: product)
            .environmentObject(self)
    }

    func reviewListSheetView() -> some View {
        ReviewListView()
            .environmentObject(self)
    }

    func reviewComposerSheetView() -> some View {
        ReviewWriteView(editingReview: editingReview)
            .environmentObject(self)
    }

    func reviewDetailSheet(for review: HotdogReview) -> some View {
        ReviewDetailView(review: review)
            .environmentObject(self)
    }

    private func filteredProducts(searchText: String, category: String) -> [Product] {
        products.filter { product in
            let matchesCategory = category == "전체" || product.category == category
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = keyword.isEmpty || product.name.localizedCaseInsensitiveContains(keyword) || product.description.localizedCaseInsensitiveContains(keyword)
            return matchesCategory && matchesSearch
        }
        .sorted {
            if $0.isSoldOut != $1.isSoldOut {
                return !$0.isSoldOut && $1.isSoldOut
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private func chatbotReply(for question: String) -> String {
        if question.contains("사료") {
            return "\(selectedDog.name)은 \(selectedDog.breed)라서 저알러지 연어 사료나 소화가 쉬운 레시피가 잘 맞아요."
        }
        if question.contains("간식") {
            return "훈련 보상용으로는 오리 말랑 간식처럼 한입 크기 제품이 잘 맞아요."
        }
        if question.contains("옷") || question.contains("하네스") {
            return "\(selectedDog.name)의 현재 체중은 \(selectedDog.weight)라서 S 또는 M 시작 핏을 먼저 확인해보는 게 좋아요."
        }
        if question.contains("장난감") {
            return "노즈워크 당근 장난감처럼 에너지 분산에 도움이 되는 제품을 추천해요."
        }
        return "\(selectedDog.name) 기준으로 질문을 분석했어요. 건강, 식단, 산책, 용품 중 하나로 더 구체적으로 물어보면 추천을 더 정확하게 줄 수 있어요."
    }

    private func sanitizedChatbotOptions(_ options: [String]) -> [String] {
        options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: SessionStorage.key) else { return }
        guard let session = try? JSONDecoder().decode(UserSession.self, from: data) else { return }
        currentUserSeq = session.userSeq
        currentUserName = session.userName
        currentUserID = session.userID
        currentUserPhone = session.userPhone
        currentUserQuickPinHash = session.quickPinHash
        isLoggedIn = true
        isSessionLocked = true
        shouldRequireQuickPinSetup = !hasQuickPin
    }

    private func saveSession(userSeq: Int, userName: String?, userID: String, userPhone: String?, quickPinHash: String?) {
        let session = UserSession(userSeq: userSeq, userName: userName, userID: userID, userPhone: userPhone, quickPinHash: quickPinHash)
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: SessionStorage.key)
    }

    private func removeSession() {
        UserDefaults.standard.removeObject(forKey: SessionStorage.key)
    }

    private func setDogOnboardingPending(_ pending: Bool, for userSeq: Int) {
        UserDefaults.standard.set(pending, forKey: SessionStorage.dogOnboardingKey(for: userSeq))
    }

    private func isDogOnboardingPending(for userSeq: Int) -> Bool {
        UserDefaults.standard.bool(forKey: SessionStorage.dogOnboardingKey(for: userSeq))
    }

    private var cartStorageKey: String {
        if let currentUserSeq {
            return SessionStorage.cartKey(for: currentUserSeq)
        }
        return SessionStorage.guestCartKey
    }

    private var favoritesStorageKey: String {
        if let currentUserSeq {
            return SessionStorage.favoritesKey(for: currentUserSeq)
        }
        return SessionStorage.guestFavoritesKey
    }

    private var readNotificationsStorageKey: String {
        if let currentUserSeq {
            return SessionStorage.readNotificationsKey(for: currentUserSeq)
        }
        return SessionStorage.guestReadNotificationsKey
    }

    private func notificationKey(for notification: AppNotificationItem) -> String {
        "\(notification.category)|\(notification.title)|\(notification.detail)"
    }

    private func readNotificationKeys() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: readNotificationsStorageKey) ?? [])
    }

    private func saveReadNotificationKey(for notification: AppNotificationItem) {
        var keys = readNotificationKeys()
        keys.insert(notificationKey(for: notification))
        UserDefaults.standard.set(Array(keys), forKey: readNotificationsStorageKey)
    }

    private func applyReadState(to fetchedNotifications: [AppNotificationItem]) -> [AppNotificationItem] {
        let readKeys = readNotificationKeys()
        return fetchedNotifications.map { notification in
            var updated = notification
            if readKeys.contains(notificationKey(for: notification)) {
                updated.isNew = false
            }
            return updated
        }
    }

    private func saveCartToLocalStorage() {
        let productSeqs = cartProductIDs.compactMap { productID in
            products.first(where: { $0.id == productID })?.dbSeq
        }
        UserDefaults.standard.set(productSeqs, forKey: cartStorageKey)
    }

    private func saveFavoritesToLocalStorage() {
        let productSeqs = favoriteProductIDs.compactMap { productID in
            products.first(where: { $0.id == productID })?.dbSeq
        }
        UserDefaults.standard.set(productSeqs, forKey: favoritesStorageKey)
    }

    private func restoreCartFromLocalStorage() {
        let savedSeqs = UserDefaults.standard.array(forKey: cartStorageKey) as? [Int] ?? []
        guard !savedSeqs.isEmpty, !products.isEmpty else {
            cartProductIDs = []
            return
        }

        let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
            if let dbSeq = product.dbSeq {
                result[dbSeq] = product
            }
        }
        cartProductIDs = savedSeqs.compactMap { productsBySeq[$0]?.id }
    }

    private func restoreFavoritesFromLocalStorage() {
        let savedSeqs = UserDefaults.standard.array(forKey: favoritesStorageKey) as? [Int] ?? []
        guard !savedSeqs.isEmpty, !products.isEmpty else {
            favoriteProductIDs = []
            return
        }

        let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
            if let dbSeq = product.dbSeq {
                result[dbSeq] = product
            }
        }
        favoriteProductIDs = Set(savedSeqs.compactMap { productsBySeq[$0]?.id })
    }

    private func quickPinHash(for pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func saveQuickPinState(pin: String, pinHash: String) {
        currentUserQuickPinHash = pinHash
        AuthCredentialStore.saveQuickPin(pin)
        if let currentUserSeq, let currentUserID {
            saveSession(userSeq: currentUserSeq, userName: currentUserName, userID: currentUserID, userPhone: currentUserPhone, quickPinHash: pinHash)
        }
        shouldRequireQuickPinSetup = false
        isSessionLocked = false
        authErrorMessage = nil
    }

    private func isValidPassword(_ text: String) -> Bool {
        guard text.count >= 8 else { return false }
        let hasLetter = text.range(of: "[A-Za-z]", options: .regularExpression) != nil
        return hasLetter
    }

    private func isValidEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,64}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
    }

    private func evaluateBiometric(context: LAContext) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "빠른 로그인을 위해 생체인증을 사용합니다."
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
