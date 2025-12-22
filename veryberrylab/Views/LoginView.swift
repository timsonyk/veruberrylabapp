import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var step: Int = 1
    @State private var loading = false
    @State private var error: String?
    
    private let authService = AuthService()
    
    var body: some View {
        Form {
            Section("Телефон") {
                TextField("+7...", text: $phone)
                    .keyboardType(.phonePad)
            }
            if step == 2 {
                Section("Код") {
                    TextField("XXXX", text: $code)
                        .keyboardType(.numberPad)
                }
            }
            Button(step == 1 ? "Отправить код" : "Войти") {
                Task { await proceed() }
            }
            .disabled(loading)
        }
        .navigationTitle("Вход")
        .alert(isPresented: Binding(get: { error != nil }, set: { _ in error = nil })) {
            Alert(title: Text("Ошибка"), message: Text(error ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    private func proceed() async {
        loading = true
        do {
            if step == 1 {
                try await authService.requestCode(phone: phone)
                step = 2
            } else {
                try await appState.login(phone: phone, code: code)
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

