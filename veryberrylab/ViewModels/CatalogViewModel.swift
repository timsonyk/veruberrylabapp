import Foundation

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var banners: [BannerDTO] = []
    @Published var categories: [CategoryDTO] = []
    @Published var products: [ProductDTO] = []
    @Published var selectedCategory: Int?
    @Published var loading = false
    @Published var error: String?
    
    private let service = CatalogService()
    
    func loadAll() async {
        loading = true
        do {
            async let b = service.fetchBanners()
            async let c = service.fetchCategories()
            async let p = service.fetchProducts(categoryId: nil)
            let (bannersResp, categoriesResp, productsResp) = try await (b, c, p)
            banners = bannersResp
            categories = categoriesResp
            products = productsResp
            selectedCategory = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
    
    func selectCategory(id: Int?) async {
        selectedCategory = id
        loading = true
        do {
            products = try await service.fetchProducts(categoryId: id)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

