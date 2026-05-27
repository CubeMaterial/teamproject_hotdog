import Combine
import MapKit
import SwiftUI

struct PaymentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var addressSearch = AddressSearchController()

    @State private var recipientName = ""
    @State private var recipientPhone = ""
    @State private var address = ""
    @State private var selectedPaymentMethod = "카드 결제"
    @State private var paymentConfirmation: PaymentConfirmation?

    private let paymentMethods = ["카드 결제", "간편 결제", "무통장 입금"]

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    orderItemsSection(palette: palette)
                    deliverySection(palette: palette)
                    paymentMethodSection(palette: palette)
                    summarySection(palette: palette)


                    Button {
                        paymentConfirmation = PaymentConfirmation(
                            method: selectedPaymentMethod,
                            address: resolvedAddress,
                            totalPrice: appState.checkoutTotalPrice
                        )
                    } label: {
                        Group {
                            if appState.isProcessingPayment {
                                ProgressView().tint(.white)
                            } else {
                                Text("결제하기")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(isFormValid ? palette.primary : palette.textSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormValid || appState.isProcessingPayment)
                }
                .padding(20)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("결제")
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
                applyCurrentUserDefaults()
                Task {
                    await appState.loadSavedAddresses()
                }
            }
            .onChange(of: appState.currentUserPhone) { _, _ in
                applyCurrentUserDefaults()
            }
            .navigationDestination(item: $paymentConfirmation) { confirmation in
                PaymentMethodConfirmationView(confirmation: confirmation) {
                    dismiss()
                }
                .environmentObject(appState)
            }
        }
    }

    private var isFormValid: Bool {
        !appState.checkoutItems.isEmpty &&
        !recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !recipientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var resolvedAddress: String {
        "\(recipientName.trimmingCharacters(in: .whitespacesAndNewlines)) / \(recipientPhone.trimmingCharacters(in: .whitespacesAndNewlines)) / \(address.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func applyCurrentUserDefaults() {
        if recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            recipientName = appState.currentUserDisplayName
        }
        if recipientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let currentUserPhone = appState.currentUserPhone?.trimmingCharacters(in: .whitespacesAndNewlines),
           !currentUserPhone.isEmpty {
            recipientPhone = currentUserPhone
        }
    }

    private func orderItemsSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("주문 상품", palette: palette)

            ForEach(appState.checkoutItems) { item in
                HStack(spacing: 12) {
                    ProductImageView(product: item.product, contentMode: .fit)
                        .frame(width: 58, height: 58)
                        .background(palette.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.product.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text("\(item.quantity)개 · \((item.product.price * item.quantity).formatted())원")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.primary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func deliverySection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("배송 정보", palette: palette)
            paymentTextField("받는 사람", text: $recipientName, palette: palette)
            paymentTextField("연락처", text: $recipientPhone, palette: palette, keyboardType: .phonePad)
            recentAddressSection(palette: palette)
            addressSearchField(palette: palette)
        }
    }

    @ViewBuilder
    private func recentAddressSection(palette: AppPalette) -> some View {
        if appState.isLoadingAddresses {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(palette.primary)
                Text("최근 배송지를 불러오는 중")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.vertical, 4)
        } else if !appState.savedAddresses.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("최근 배송지")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)

                ForEach(appState.savedAddresses.prefix(3)) { savedAddress in
                    Button {
                        applySavedAddress(savedAddress)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(savedAddress.address)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(2)
                            Text(savedAddress.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addressSearchField(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(palette.textSecondary)
                TextField("배송지 주소 검색", text: $address)
                    .font(.system(size: 14))
                    .onChange(of: address) { _, newValue in
                        addressSearch.updateQuery(newValue)
                    }
            }
            .padding(14)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !addressSearch.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(addressSearch.suggestions.prefix(5), id: \.self) { suggestion in
                        Button {
                            address = addressSearch.displayText(for: suggestion)
                            addressSearch.clear()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(palette.textPrimary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        }
                        .buttonStyle(.plain)

                        if suggestion != addressSearch.suggestions.prefix(5).last {
                            Divider()
                        }
                    }
                }
                .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func paymentMethodSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("결제 수단", palette: palette)
            Picker("결제 수단", selection: $selectedPaymentMethod) {
                ForEach(paymentMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func summarySection(palette: AppPalette) -> some View {
        VStack(spacing: 10) {
            summaryRow("상품 금액", value: "\(appState.checkoutTotalPrice.formatted())원", palette: palette)
            summaryRow("배송비", value: "무료", palette: palette)
            Divider()
            summaryRow("총 결제 금액", value: "\(appState.checkoutTotalPrice.formatted())원", palette: palette, isTotal: true)
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionTitle(_ title: String, palette: AppPalette) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(palette.textPrimary)
    }

    private func paymentTextField(_ placeholder: String, text: Binding<String>, palette: AppPalette, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .font(.system(size: 14))
            .padding(14)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryRow(_ title: String, value: String, palette: AppPalette, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 16 : 14, weight: isTotal ? .bold : .medium))
                .foregroundStyle(isTotal ? palette.textPrimary : palette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: isTotal ? 18 : 14, weight: .bold))
                .foregroundStyle(isTotal ? palette.primary : palette.textPrimary)
        }
    }

    private func applySavedAddress(_ savedAddress: SavedAddress) {
        address = savedAddress.address
        addressSearch.clear()

        let parts = savedAddress.name
            .components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let name = parts.first {
            recipientName = name
        }
        if parts.count > 1 {
            recipientPhone = parts[1]
        }
    }
}

private struct PaymentConfirmation: Identifiable, Hashable {
    let id = UUID()
    let method: String
    let address: String
    let totalPrice: Int
}

private struct PaymentMethodConfirmationView: View {
    @EnvironmentObject private var appState: AppState
    let confirmation: PaymentConfirmation
    let onCompleted: () -> Void

    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVC = ""
    @State private var easyPayProvider = "HOTDOG Pay"
    @State private var depositorName = ""

    private let easyPayProviders = ["HOTDOG Pay", "KakaoPay", "Naver Pay", "Apple Pay"]

    var body: some View {
        let palette = appState.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection(palette: palette)
                methodSpecificSection(palette: palette)
                finalSummarySection(palette: palette)
                confirmButton(palette: palette)
            }
            .padding(20)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(confirmation.method)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: cardNumber) { _, newValue in
            cardNumber = formatCardNumber(newValue)
        }
        .onChange(of: cardExpiry) { _, newValue in
            cardExpiry = formatExpiry(newValue)
        }
        .onChange(of: cardCVC) { _, newValue in
            cardCVC = String(newValue.filter(\.isNumber).prefix(3))
        }
    }

    private var canConfirm: Bool {
        switch confirmation.method {
        case "카드 결제":
            return cardNumber.filter(\.isNumber).count == 16 &&
                cardExpiry.filter(\.isNumber).count == 4 &&
                cardCVC.count == 3
        case "무통장 입금":
            return !depositorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    private func headerSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(paymentTitle)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(palette.textPrimary)
            Text(paymentDescription)
                .font(.system(size: 14))
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func methodSpecificSection(palette: AppPalette) -> some View {
        switch confirmation.method {
        case "카드 결제":
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("카드 정보", palette: palette)
                paymentField("카드 번호", text: $cardNumber, palette: palette, keyboardType: .numberPad)
                HStack(spacing: 10) {
                    paymentField("MM/YY", text: $cardExpiry, palette: palette, keyboardType: .numberPad)
                    paymentField("CVC", text: $cardCVC, palette: palette, keyboardType: .numberPad)
                }
            }
        case "간편 결제":
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("간편 결제 선택", palette: palette)
                ForEach(easyPayProviders, id: \.self) { provider in
                    Button {
                        easyPayProvider = provider
                    } label: {
                        HStack {
                            Image(systemName: easyPayProvider == provider ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(easyPayProvider == provider ? palette.accent : palette.textSecondary)
                            Text(provider)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                            Spacer()
                        }
                        .padding(14)
                        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("입금 정보", palette: palette)
                infoRow("은행", value: "HOTDOG Bank", palette: palette)
                infoRow("계좌번호", value: "100-2026-0513", palette: palette)
                infoRow("예금주", value: "주식회사 HOTDOG", palette: palette)
                paymentField("입금자명", text: $depositorName, palette: palette)
            }
        }
    }

    private func finalSummarySection(palette: AppPalette) -> some View {
        VStack(spacing: 10) {
            infoRow("결제 수단", value: confirmation.method, palette: palette)
            infoRow("배송지", value: confirmation.address, palette: palette)
            Divider()
            infoRow("결제 금액", value: "\(confirmation.totalPrice.formatted())원", palette: palette, isEmphasized: true)
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func confirmButton(palette: AppPalette) -> some View {
        Button {
            Task {
                let success = await appState.completePayment(
                    address: confirmation.address,
                    paymentMethod: resolvedPaymentMethod
                )
                if success {
                    onCompleted()
                }
            }
        } label: {
            Group {
                if appState.isProcessingPayment {
                    ProgressView().tint(.white)
                } else {
                    Text(confirmButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(canConfirm ? palette.primary : palette.textSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm || appState.isProcessingPayment)
    }

    private var resolvedPaymentMethod: String {
        if confirmation.method == "간편 결제" {
            return "\(confirmation.method) - \(easyPayProvider)"
        }
        return confirmation.method
    }

    private var paymentTitle: String {
        switch confirmation.method {
        case "카드 결제":
            return "카드 정보를 확인해주세요"
        case "간편 결제":
            return "사용할 간편 결제를 선택해주세요"
        default:
            return "입금 정보를 확인해주세요"
        }
    }

    private var paymentDescription: String {
        switch confirmation.method {
        case "카드 결제":
            return "카드 정보 확인 후 주문이 바로 접수됩니다."
        case "간편 결제":
            return "선택한 간편 결제 수단으로 주문을 진행합니다."
        default:
            return "입금자명을 입력하면 주문이 접수되고 배송 준비 상태로 관리됩니다."
        }
    }

    private var confirmButtonTitle: String {
        confirmation.method == "무통장 입금" ? "입금 주문 접수" : "결제 완료"
    }

    private func sectionTitle(_ title: String, palette: AppPalette) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(palette.textPrimary)
    }

    private func paymentField(_ placeholder: String, text: Binding<String>, palette: AppPalette, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .font(.system(size: 14))
            .padding(14)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func infoRow(_ title: String, value: String, palette: AppPalette, isEmphasized: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: isEmphasized ? 17 : 14, weight: isEmphasized ? .bold : .semibold))
                .foregroundStyle(isEmphasized ? palette.primary : palette.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func formatCardNumber(_ value: String) -> String {
        let digits = String(value.filter(\.isNumber).prefix(16))
        return stride(from: 0, to: digits.count, by: 4)
            .map { index in
                let start = digits.index(digits.startIndex, offsetBy: index)
                let end = digits.index(start, offsetBy: min(4, digits.distance(from: start, to: digits.endIndex)))
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }

    private func formatExpiry(_ value: String) -> String {
        let digits = String(value.filter(\.isNumber).prefix(4))
        guard digits.count > 2 else { return digits }
        let month = digits.prefix(2)
        let year = digits.dropFirst(2)
        return "\(month)/\(year)"
    }
}

private final class AddressSearchController: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            clear()
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    func displayText(for suggestion: MKLocalSearchCompletion) -> String {
        if suggestion.subtitle.isEmpty {
            return suggestion.title
        }
        return "\(suggestion.title) \(suggestion.subtitle)"
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
        }
    }
}

#Preview {
    PaymentView()
        .environmentObject(AppState())
}
