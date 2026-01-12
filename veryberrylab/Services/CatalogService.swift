import Foundation

// MARK: - Delivery Check Response

struct DeliveryCheckResponse: Codable {
    let available: Bool
    let delivery_fee: Double
    let sla_minutes: Int
    let min_order_total: Double?
    let zone_name: String?
}

// MARK: - Delivery Zone

struct DeliveryZoneDTO: Codable, Identifiable {
    let id: Int
    let city: String
    let name: String
    let polygon: [[Double]]?
    let delivery_fee: Double
    let sla_minutes: Int
    let min_order_total: Double?
    let is_active: Bool
}

// MARK: - Catalog Service

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
    
    func checkDelivery(lat: Double, lng: Double, city: String = "Москва") async throws -> DeliveryCheckResponse {
        let body: [String: Any] = [
            "lat": lat,
            "lng": lng,
            "city": city
        ]
        return try await client.request(["catalog", "delivery-check"], method: "POST", body: body)
    }
    
    func fetchDeliveryZones(city: String = "Москва") async throws -> [DeliveryZoneDTO] {
        let query = [URLQueryItem(name: "city", value: city)]
        return try await client.request(["catalog", "delivery-zones"], queryItems: query)
    }

    func fetchPickupLocations() async throws -> [PickupPoint] {
        try await client.request(["catalog", "store_locations"])
    }
}

