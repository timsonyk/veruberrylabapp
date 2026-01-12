import SwiftUI
import UIKit

/// A view that asynchronously loads and displays an image with caching.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // Check memory cache first
        if let cached = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cached
            return
        }

        isLoading = true

        // Create request with caching policy
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let uiImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            // Store in memory cache
            ImageCache.shared.set(uiImage, forKey: url.absoluteString)

            DispatchQueue.main.async {
                self.image = uiImage
                isLoading = false
            }
        }.resume()
    }
}

/// Simple memory cache for images
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100 // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}

// Convenience extension for simpler usage
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}
