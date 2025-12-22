import Foundation

struct CategoryDTO: Codable, Identifiable {
    let id: Int?
    let name: String?
    let sort_order: Int?
    let is_active: Bool?
}

struct ProductSizeDTO: Codable, Identifiable {
    let id: Int?
    let name: String?
    let base_price: Double?
    let sort_order: Int?
}

struct ModificationOptionDTO: Codable, Identifiable {
    let id: Int?
    let name: String?
    let extra_price: Double?
    let image_url: String?
    let is_default: Bool?
    let sort_order: Int?
    let is_active: Bool?
}

struct ModificationGroupDTO: Codable, Identifiable {
    let id: Int?
    let name: String?
    let min_count: Int?
    let max_count: Int?
    let type: String?
    let sort_order: Int?
    let is_active: Bool?
    let options: [ModificationOptionDTO]?
}

struct ProductDTO: Codable, Identifiable {
    let id: Int?
    let category_id: Int?
    let name: String?
    let description: String?
    let base_price: Double?
    let size_label: String?
    let is_active: Bool?
    let media: [String]?
    let sort_order: Int?
    let sizes: [ProductSizeDTO]?
    let modification_groups: [ModificationGroupDTO]?
}

struct BannerDTO: Codable, Identifiable {
    let id: Int?
    let title: String?
    let subtitle: String?
    let image_url: String?
    let sort_order: Int?
    let is_active: Bool?
}

struct AuthResponseDTO: Codable {
    let access_token: String
    let token_type: String
    let user: UserDTO
    let expires_in: Int
    let issued_at: String
}

struct UserDTO: Codable, Identifiable {
    let id: Int
    let phone: String
    let name: String?
    let email: String?
    let city: String?
    let birthday: String?
    let created_at: String
}

