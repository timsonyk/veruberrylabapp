import Foundation

// MARK: - Telegram Bot Auth Response

struct TelegramBotInitResponse: Codable {
    let status: String
    let phone: String
    let bot_username: String
    let deep_link: String
}

struct TelegramBotAuthStatus: Codable {
    let status: String  // "pending", "completed", "expired"
    let access_token: String?
    let user: UserDTO?
    let expires_in: Int?
    let issued_at: String?
}

// MARK: - Auth Service

final class AuthService {
    private let client = APIClient.shared

    // MARK: - Telegram Bot Auth

    /// Initialize Telegram bot authentication flow
    func initTelegramAuth(phone: String) async throws -> TelegramBotInitResponse {
        struct Payload: Codable { let phone: String }
        let body = try JSONEncoder().encode(Payload(phone: phone))
        return try await client.request(["auth", "telegram-bot", "init"], method: "POST", body: body)
    }

    /// Check if Telegram bot auth is completed
    func checkTelegramAuth(phone: String) async throws -> TelegramBotAuthStatus {
        struct Payload: Codable { let phone: String }
        let body = try JSONEncoder().encode(Payload(phone: phone))
        return try await client.request(["auth", "telegram-bot", "check"], method: "POST", body: body)
    }
}
