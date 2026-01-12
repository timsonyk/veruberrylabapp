import Foundation

// MARK: - Order Request/Response Models

struct CreateOrderRequest: Codable {
    let items: [OrderItemRequest]
    let delivery_type: String
    let address_text: String?
    let lat: Double?
    let lng: Double?
    let city: String?
    let pickup_location_id: Int?
    let comment: String?
    let no_call: Bool?
    let promo_code: String?
}

struct OrderItemRequest: Codable {
    let product_id: Int
    let quantity: Int
    let size_id: Int?
    let modifications_json: String?
}

struct PaymentInitResponse: Codable {
    let payment_id: Int
    let status: String
    let redirect_url: String?
    let token: String?
}

// MARK: - Order Service

final class OrderService {
    private let client = APIClient.shared

    /// Create a new order
    func createOrder(_ request: CreateOrderRequest) async throws -> OrderDTO {
        let body = try JSONEncoder().encode(request)
        return try await client.request(["orders"], method: "POST", body: body)
    }

    /// Initiate payment for an order
    func initiatePayment(orderId: Int) async throws -> PaymentInitResponse {
        return try await client.request(["orders", String(orderId), "pay"], method: "POST", body: nil)
    }

    /// Get order details
    func getOrder(orderId: Int) async throws -> OrderDTO {
        return try await client.request(["orders", String(orderId)], method: "GET", body: nil)
    }

    /// List user's orders
    func listOrders() async throws -> [OrderDTO] {
        return try await client.request(["orders"], method: "GET", body: nil)
    }
}
