import Foundation

final class AuthService {
    private let client = APIClient.shared
    
    func requestCode(phone: String) async throws {
        struct Payload: Codable { let phone: String }
        let body = try JSONEncoder().encode(Payload(phone: phone))
        struct Response: Codable { let sent: Bool }
        _ = try await client.request(["auth", "request_code"], method: "POST", body: body) as Response
    }
    
    func verify(phone: String, code: String) async throws -> AuthResponseDTO {
        struct Payload: Codable { let phone: String; let code: String }
        let body = try JSONEncoder().encode(Payload(phone: phone, code: code))
        return try await client.request(["auth", "verify"], method: "POST", body: body)
    }
}

