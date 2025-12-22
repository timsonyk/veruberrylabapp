//
//  veryberrylabApp.swift
//  veryberrylab
//
//  Created by Timofey on 10.12.2025.
//

import SwiftUI

@main
struct veryberrylabApp: App {
    @StateObject var appState = AppState()
    @StateObject var cartVM = CartViewModel()
    @StateObject var catalogVM = CatalogViewModel()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(cartVM)
                .environmentObject(catalogVM)
                .preferredColorScheme(.light)
        }
    }
}
