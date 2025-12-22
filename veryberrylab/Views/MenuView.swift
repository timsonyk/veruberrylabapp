import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationView {
            List {
                Section("FAQ") {
                    Text("Частые вопросы (заглушка)")
                }
                Section("Адрес") {
                    Text("Средняя Переславская 25с1")
                }
                Section {
                    Text("О приложении")
                    Text("Работает на Стартере")
                }
            }
            .navigationTitle("Меню")
        }
    }
}

