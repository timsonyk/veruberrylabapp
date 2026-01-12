//
//  veryberrylabApp.swift
//  veryberrylab
//
//  Created by Timofey on 10.12.2025.
//

import SwiftUI
import YandexMapsMobile

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if !AppConfig.yandexMapApiKey.isEmpty {
            YMKMapKit.setApiKey(AppConfig.yandexMapApiKey)
            YMKMapKit.setLocale("ru_RU") // Русская локализация
            // Инициализируем MapKit сразу при запуске — это ускоряет загрузку карты
            _ = YMKMapKit.sharedInstance()
        } else {
            print("Yandex Maps API key is empty. Set Info.plist key \"YMKApiKey\".")
        }
        return true
    }
}

@main
struct veryberrylabApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
