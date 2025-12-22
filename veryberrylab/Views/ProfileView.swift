import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if let user = appState.user {
                    Text(user.name ?? "Профиль")
                        .font(.title2).bold()
                    Text(user.phone).font(.subheadline)
                } else {
                    Text("Не авторизован")
                    NavigationLink("Войти") {
                        LoginView()
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Профиль")
        }
    }
}

