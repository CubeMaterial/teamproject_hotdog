import PhotosUI
import SwiftUI
import UIKit

struct DogOnboardingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var dogName = ""
    @State private var dogAge = "1살"
    @State private var dogWeight = "3-6kg"

    @State private var selectedTheme: DogColorTheme = .brown
    @State private var detectedBreed: String = "기타"

    @State private var pickedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isAnalyzingImage = false

    @State private var localErrorMessage: String?

    private let keyOrange = Color(red: 0.95, green: 0.55, blue: 0.26)
    private let deepOrange = Color(red: 0.88, green: 0.42, blue: 0.18)
    private let inkBrown = Color(red: 0.25, green: 0.13, blue: 0.07)
    private let apiClient = HotdogAPIClient()
    private var activePalette: AppPalette {
        selectedTheme.palette
    }

    private var canGoBack: Bool {
        appState.dogs.contains { $0.dbSeq != nil || $0.breed != "정보 없음" }
    }

    private let supportedBreeds: [String] = [
        "몰티즈", "푸들", "믹스견", "포메라니안", "비숑 프리제", "치와와", "시츄", "진돗개", "요크셔테리어", "골든 리트리버", "기타"
    ]
    private let ageOptions = ["1살 미만", "1살", "2살", "3살", "4살", "5살", "6살", "7살", "8살", "9살", "10살 이상"]
    private let weightOptions = ["1kg 미만", "1-3kg", "3-6kg", "6-10kg", "10-15kg", "15-20kg", "20-30kg", "30kg 이상"]

    var body: some View {
        NavigationStack {
            ZStack {
                activePalette.background
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.22), value: selectedTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        photoSection
                        profileSection
                        analysisSection
                        messageSection
                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if canGoBack {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            appState.cancelDogOnboardingIfPossible()
                        } label: {
                            Label("뒤로", systemImage: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(activePalette.primary)
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadPhoto(from: newItem)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker { image in
                let preparedImage = image.normalizedForAnalysis()
                pickedImage = preparedImage
                analyzeImage(preparedImage)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("반려견 프로필")
                .font(.system(size: 31, weight: .heavy))
                .foregroundStyle(activePalette.textPrimary)

            Text("사진과 기본 정보를 등록하면 홈, 챗봇, 상품 추천에 바로 반영됩니다.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(activePalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("사진")

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 18, y: 10)

                if let pickedImage {
                    Image(uiImage: pickedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundStyle(keyOrange)

                        Text("반려견 사진을 추가해주세요")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(inkBrown)

                        Text("사진첩에서 선택하거나 바로 촬영할 수 있습니다.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                }

                if isAnalyzingImage {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.black.opacity(0.30))
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text("사진 분석 중")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.42), in: Capsule())
                    .padding(16)
                }
            }
            .frame(height: 260)

            HStack(spacing: 10) {
                Button {
                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        localErrorMessage = "이 기기에서는 카메라 촬영을 사용할 수 없습니다."
                        return
                    }
                    showCamera = true
                } label: {
                    Label("촬영", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("사진첩", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(keyOrange)
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("기본 정보")
            inputField("이름", placeholder: "예: 초코", text: $dogName, keyboardType: .default)

            HStack(spacing: 10) {
                dropdownField("나이", selection: $dogAge, options: ageOptions)
                dropdownField("몸무게", selection: $dogWeight, options: weightOptions)
            }
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("분석 결과")

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(keyOrange)
                        .frame(width: 34, height: 34)
                        .background(keyOrange.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("견종")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Menu {
                            ForEach(supportedBreeds, id: \.self) { breed in
                                Button {
                                    detectedBreed = breed
                                } label: {
                                    Label(breed, systemImage: detectedBreed == breed ? "checkmark" : "pawprint")
                                }
                            }
                        } label: {
                            dropdownButtonContent(
                                title: detectedBreed,
                                subtitle: breedDescription(for: detectedBreed),
                                systemImage: "pawprint.fill"
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("대표 색상")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(DogColorTheme.allCases) { theme in
                            themeButton(theme)
                        }
                    }
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let localErrorMessage {
            messageView(localErrorMessage, color: .red)
        }

    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Group {
                if appState.isSavingDogProfile {
                    ProgressView().tint(.white)
                } else {
                    Label("등록하고 시작하기", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [keyOrange, deepOrange], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: deepOrange.opacity(0.26), radius: 12, y: 7)
        }
        .buttonStyle(.plain)
        .disabled(appState.isSavingDogProfile)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(activePalette.textPrimary)
    }

    private func inputField(_ title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(activePalette.textSecondary)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }

    private func dropdownField(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(activePalette.textSecondary)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Label(option, systemImage: selection.wrappedValue == option ? "checkmark" : optionIcon(for: title))
                    }
                }
            } label: {
                dropdownButtonContent(
                    title: selection.wrappedValue,
                    subtitle: optionDescription(for: title, value: selection.wrappedValue),
                    systemImage: optionIcon(for: title)
                )
            }
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }

    private func dropdownButtonContent(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(keyOrange)
                .frame(width: 32, height: 32)
                .background(keyOrange.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(inkBrown)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(keyOrange.opacity(0.14), lineWidth: 1)
        )
    }

    private func optionIcon(for title: String) -> String {
        title == "나이" ? "calendar" : "scalemass"
    }

    private func optionDescription(for title: String, value: String) -> String {
        if title == "나이" {
            if value == "1살 미만" { return "퍼피" }
            if value == "10살 이상" { return "시니어" }
            guard let age = Int(value.replacingOccurrences(of: "살", with: "")) else { return "연령 선택" }
            if age <= 2 { return "성장기" }
            if age <= 7 { return "성견" }
            return "시니어"
        }

        switch value {
        case "1kg 미만", "1-3kg":
            return "초소형"
        case "3-6kg":
            return "소형견"
        case "6-10kg":
            return "중소형견"
        case "10-15kg":
            return "중형견"
        case "15-20kg":
            return "중대형견"
        case "20-30kg":
            return "대형견"
        case "30kg 이상":
            return "초대형견"
        default:
            return "체중 범위"
        }
    }

    private func breedDescription(for breed: String) -> String {
        breed == "기타" ? "직접 선택" : "분석 결과를 확인하세요"
    }

    private func themeButton(_ theme: DogColorTheme) -> some View {
        Button {
            selectedTheme = theme
        } label: {
            VStack(spacing: 7) {
                Circle()
                    .fill(themePreviewColor(theme))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(selectedTheme == theme ? keyOrange : Color.black.opacity(0.12), lineWidth: selectedTheme == theme ? 3 : 1)
                    )
                Text(theme.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedTheme == theme ? inkBrown : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selectedTheme == theme ? keyOrange.opacity(0.12) : Color(red: 0.98, green: 0.97, blue: 0.95),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func themePreviewColor(_ theme: DogColorTheme) -> Color {
        switch theme {
        case .black:
            return Color(red: 0.10, green: 0.10, blue: 0.11)
        case .gray:
            return Color(red: 0.58, green: 0.60, blue: 0.63)
        case .white:
            return Color(red: 0.96, green: 0.93, blue: 0.88)
        case .brown:
            return Color(red: 0.58, green: 0.36, blue: 0.20)
        }
    }

    private func messageView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        await MainActor.run {
            isAnalyzingImage = true
            localErrorMessage = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let rawImage = UIImage(data: data) else {
                await MainActor.run {
                    isAnalyzingImage = false
                    localErrorMessage = "사진을 불러오지 못했습니다."
                }
                return
            }

            let preparedImage = rawImage.normalizedForAnalysis()
            await MainActor.run {
                pickedImage = preparedImage
            }
            await analyzeImage(preparedImage)
        } catch {
            await MainActor.run {
                isAnalyzingImage = false
                localErrorMessage = "사진을 불러오지 못했습니다. 다시 선택해주세요."
            }
        }
    }

    private func analyzeImage(_ image: UIImage) {
        Task {
            await analyzeImage(image)
        }
    }

    private func analyzeImage(_ image: UIImage) async {
        await MainActor.run {
            isAnalyzingImage = true
            localErrorMessage = nil
        }

        guard let imageData = image.jpegData(compressionQuality: 0.86) else {
            await MainActor.run {
                detectedBreed = "기타"
                isAnalyzingImage = false
                localErrorMessage = "사진을 분석 가능한 형식으로 변환하지 못했습니다."
            }
            return
        }

        do {
            let analysis = try await apiClient.analyzeDogImage(imageData: imageData)
            let breed = analysis.resolvedBreed

            await MainActor.run {
                detectedBreed = supportedBreeds.contains(breed) ? breed : "기타"
                selectedTheme = analysis.resolvedTheme
                isAnalyzingImage = false
            }
        } catch {
            await MainActor.run {
                detectedBreed = "기타"
                isAnalyzingImage = false
                localErrorMessage = "강아지 분석 봇과 연결하지 못했습니다. API 서버 상태를 확인해주세요."
            }
        }
    }

    private func submit() {
        let name = dogName.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = dogAge.trimmingCharacters(in: .whitespacesAndNewlines)
        let weight = dogWeight.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !age.isEmpty, !weight.isEmpty else {
            localErrorMessage = "이름, 나이, 몸무게를 모두 입력해주세요."
            return
        }

        localErrorMessage = nil
        Task {
            let success = await appState.completeDogOnboarding(
                name: name,
                breed: detectedBreed,
                age: age,
                weight: weight,
                theme: selectedTheme,
                imageDataURI: dogImageDataURI()
            )
            if !success {
                localErrorMessage = appState.dogOnboardingErrorMessage ?? appState.apiErrorMessage ?? "강아지 정보를 저장하지 못했습니다."
            }
        }
    }

    private func dogImageDataURI() -> String? {
        guard let image = pickedImage else {
            return nil
        }
        let resizedImage = image.normalizedForAnalysis(maxDimension: 900)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.68) else {
            return nil
        }
        return "data:image/jpeg;base64,\(imageData.base64EncodedString())"
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

private extension UIImage {
    func normalizedForAnalysis(maxDimension: CGFloat = 1400) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, size.width > 0, size.height > 0 else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

#Preview {
    DogOnboardingView()
        .environmentObject(AppState())
}
