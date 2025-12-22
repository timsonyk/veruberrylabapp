import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case decoding
    case server(status: Int)
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .decoding: return "Failed to decode response"
        case .server(let status): return "Server error \(status)"
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown error"
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}
    
    private var token: String?
    
    func setToken(_ token: String?) {
        self.token = token
    }
    
    private func makeURL(components: [String], queryItems: [URLQueryItem]? = nil) -> URL {
        let base = components.reduce(AppConfig.apiBaseURL) { partial, comp in
            partial.appendingPathComponent(comp)
        }
        if let queryItems, var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) {
            comps.queryItems = queryItems
            return comps.url ?? base
        }
        return base
    }
    
    func request<T: Decodable>(_ endpoint: [String], method: String = "GET", body: Data? = nil, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let url = makeURL(components: endpoint, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        switch http.statusCode {
        case 200..<300:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.server(status: http.statusCode)
        }
    }
}

