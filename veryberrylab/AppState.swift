import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var token: String? {
        didSet { APIClient.shared.setToken(token) }
    }
    @Published var user: UserDTO?
    
    private let authService = AuthService()
    
    func login(phone: String, code: String) async throws {
        let resp = try await authService.verify(phone: phone, code: code)
        token = resp.access_token
        user = resp.user
    }
}

