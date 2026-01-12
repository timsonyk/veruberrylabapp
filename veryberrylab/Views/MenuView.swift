import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Помощь") {
                    NavigationLink("Частые вопросы") {
                        FAQView()
                }
                }
                
                Section("Контакты") {
                    NavigationLink("Наши адреса") {
                        StoreLocationsView()
                    }
                }
            }
            .navigationTitle("Меню")
        }
    }
}

