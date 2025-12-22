//
//  veryberrylabApp.swift
//  veryberrylab
//
//  Created by Timofey on 10.12.2025.
//

import SwiftUI
#if canImport(YandexMapsMobile)
import YandexMapsMobile

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if !AppConfig.yandexMapApiKey.isEmpty {
            YMKMapKit.setApiKey(AppConfig.yandexMapApiKey)
        } else {
            print("Yandex Maps API key is empty. Set Info.plist key \"YMKApiKey\".")
        }
        return true
    }
}
#endif

@main
struct veryberrylabApp: App {
#if canImport(YandexMapsMobile)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    @StateObject var appState = AppState()
    @StateObject var cartVM = CartViewModel()
    @StateObject var catalogVM = CatalogViewModel()
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(cartVM)
                .environmentObject(catalogVM)
                .preferredColorScheme(.light)
        }
    }
}
