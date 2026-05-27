import SwiftUI
import UIKit

struct ProductImageView: View {
    let product: Product
    let contentMode: ContentMode
    @State private var shouldUseThumbnailURL = false

    init(product: Product, contentMode: ContentMode = .fill) {
        self.product = product
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let urlString = resolvedURLString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallbackAfterURLFailure
                    default:
                        placeholder
                    }
                }
            } else if let image = decodedUIImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
    }

    private var resolvedURLString: String? {
        if shouldUseThumbnailURL {
            return product.thumbnailURL ?? product.imageURL
        }
        return product.imageURL ?? product.thumbnailURL
    }

    @ViewBuilder
    private var fallbackAfterURLFailure: some View {
        if !shouldUseThumbnailURL, product.thumbnailURL != nil, product.thumbnailURL != product.imageURL {
            placeholder
                .task {
                    shouldUseThumbnailURL = true
                }
        } else if let image = decodedUIImage {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholder
        }
    }

    private var decodedUIImage: UIImage? {
        if let image = decodeBase64ToImage(product.imageBase64) {
            return image
        }
        if let image = decodeBase64ToImage(product.thumbnailBase64) {
            return image
        }
        return nil
    }

    private func decodeBase64ToImage(_ rawBase64: String?) -> UIImage? {
        guard let rawBase64, !rawBase64.isEmpty else { return nil }

        let normalized = rawBase64
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let data = Data(base64Encoded: normalized, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
