import Foundation

enum AppConfig {
    // TODO: move to Info.plist/xcconfig if needed
    static let apiBaseURL = URL(string: "https://expurgatory-stockier-cornell.ngrok-free.dev")!
    
    /// Yandex Maps API key. Provide via Info.plist key "YMKApiKey".
    static var yandexMapApiKey: String {
        Bundle.main.infoDictionary?["YMKApiKey"] as? String ?? ""
    }
}

