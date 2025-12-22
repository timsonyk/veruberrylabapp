import Foundation

final class CatalogService {
    private let client = APIClient.shared
    
    func fetchBanners() async throws -> [BannerDTO] {
        try await client.request(["catalog", "banners"])
    }
    
    func fetchCategories() async throws -> [CategoryDTO] {
        try await client.request(["catalog", "categories"])
    }
    
    func fetchProducts(categoryId: Int?) async throws -> [ProductDTO] {
        let query = categoryId.map { [URLQueryItem(name: "category_id", value: "\($0)")] }
        return try await client.request(["catalog", "products"], queryItems: query)
    }
    
    func fetchProduct(id: Int) async throws -> ProductDTO {
        try await client.request(["catalog", "products", "\(id)"])
    }
}

