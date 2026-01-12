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

struct LoyaltyInfoDTO: Codable {
    let points_available: Double
    let points_spent: Double
    let cashback_percent: Double
    let orders_count: Int
    let orders_sum: Double
    let first_order_date: String?
}

struct OrderDTO: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let status: String
    let delivery_type: String
    let address_text: String?
    let lat: Double?
    let lng: Double?
    let city: String?
    let pickup_location_id: Int?
    let comment: String?
    let subtotal: Double
    let delivery_fee: Double
    let discount: Double
    let total: Double
    let loyalty_earned: Double
    let created_at: String
    let items: [OrderItemDTO]?
}

struct OrderItemDTO: Codable, Identifiable {
    let id: Int
    let order_id: Int
    let product_id: Int
    let product_name: String?
    let quantity: Int
    let base_price: Double
    let final_price: Double
    let total_price: Double
    let modifications_json: String?
}

// MARK: - Notification DTOs

enum NotificationType: String, Codable {
    case promo = "promo"
    case order = "order"
    case system = "system"
    case bonus = "bonus"
}

struct NotificationDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let body: String
    let notification_type: NotificationType
    let is_read: Bool
    let created_at: String
}

struct UnreadCountResponse: Codable {
    let count: Int
}

struct DeviceTokenRequest: Codable {
    let token: String
    let platform: String
}

