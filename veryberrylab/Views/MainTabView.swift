import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CatalogView()
                .tabItem {
                    Label("Каталог", systemImage: "bag")
                }
            CartView()
                .tabItem {
                    Label("Корзина", systemImage: "cart")
                }
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
            MenuView()
                .tabItem {
                    Label("Меню", systemImage: "list.bullet")
                }
        }
        .tint(.red)
    }
}

