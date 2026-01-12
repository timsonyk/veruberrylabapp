import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var phone: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isWaitingForTelegram = false
    @State private var pollingTask: Task<Void, Never>?

    private let authService = AuthService()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.95),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Logo and title
                    VStack(spacing: 16) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)

                        Text("Войдите, чтобы копить бонусы\nи делать заказы")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 48)

                    // Phone input card
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Номер телефона")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                // Country code
                                HStack(spacing: 6) {
                                    Text("🇷🇺")
                                        .font(.title2)
                                    Text("+7")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                                // Phone number field
                                TextField("900 123 45 67", text: $phone)
                                    .font(.body)
                                    .keyboardType(.phonePad)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .disabled(isWaitingForTelegram)
                            }
                        }

                        // Telegram button
                        Button(action: startTelegramAuth) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                }

                                Text(isWaitingForTelegram ? "Ожидаем подтверждение..." : "Войти через Telegram")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isWaitingForTelegram
                                        ? [Color.gray, Color.gray.opacity(0.8)]
                                        : [Color(red: 0.0, green: 0.53, blue: 0.87), Color(red: 0.0, green: 0.45, blue: 0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: isWaitingForTelegram ? .clear : Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || phone.isEmpty)
                        .opacity(phone.isEmpty ? 0.6 : 1.0)

                        // Cancel waiting button
                        if isWaitingForTelegram {
                            Button(action: cancelWaiting) {
                                Text("Отменить")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // Info section
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title3)
                                .foregroundColor(.green)

                            Text("Безопасный вход через Telegram")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)

                            Text("Не требуется SMS-код")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }
                    .padding(20)
                    .padding(.top, 24)

                    // How it works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как это работает")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 12) {
                            stepRow(number: 1, text: "Введите номер телефона")
                            stepRow(number: 2, text: "Нажмите кнопку «Войти через Telegram»")
                            stepRow(number: 3, text: "В Telegram нажмите «Поделиться номером»")
                            stepRow(number: 4, text: "Вернитесь в приложение — вы авторизованы!")
                        }
                    }
                    .padding(20)

                    Spacer(minLength: 40)
                }
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            pollingTask?.cancel()
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption2)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.red)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func formatPhone() -> String {
        let digits = phone.filter { $0.isNumber }
        if digits.hasPrefix("7") || digits.hasPrefix("8") {
            let cleaned = String(digits.dropFirst())
            return "+7\(cleaned)"
        }
        return "+7\(digits)"
    }

    private func startTelegramAuth() {
        let formattedPhone = formatPhone()
        isLoading = true

        Task {
            do {
                // Init auth on backend
                let response = try await authService.initTelegramAuth(phone: formattedPhone)

                // Open Telegram bot
                if let url = URL(string: response.deep_link) {
                    await MainActor.run {
                        UIApplication.shared.open(url)
                        isLoading = false
                        isWaitingForTelegram = true
                    }

                    // Start polling for auth completion
                    startPolling(phone: formattedPhone)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Не удалось начать авторизацию. Попробуйте позже."
                    showError = true
                }
            }
        }
    }

    private func startPolling(phone: String) {
        pollingTask?.cancel()

        pollingTask = Task {
            // Poll every 2 seconds for up to 3 minutes
            for i in 0..<90 {
                if Task.isCancelled { break }

                do {
                    let status = try await authService.checkTelegramAuth(phone: phone)
                    print("🔄 Poll #\(i+1): status=\(status.status), token=\(status.access_token != nil), user=\(status.user != nil)")

                    if status.status == "completed",
                       let token = status.access_token,
                       let user = status.user {
                        print("✅ Auth completed! Setting token and user...")
                        await MainActor.run {
                            appState.token = token
                            appState.user = user
                        }
                        await appState.fetchLoyaltyInfo()
                        await MainActor.run {
                            dismiss()
                        }
                        return
                    } else if status.status == "expired" {
                        print("⏰ Auth session expired")
                        await MainActor.run {
                            isWaitingForTelegram = false
                            errorMessage = "Сессия истекла. Попробуйте снова."
                            showError = true
                        }
                        return
                    }
                } catch {
                    print("❌ Polling error: \(error)")
                    // Continue polling even on error
                }

                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }

            // Timeout
            await MainActor.run {
                isWaitingForTelegram = false
                errorMessage = "Время ожидания истекло. Попробуйте снова."
                showError = true
            }
        }
    }

    private func cancelWaiting() {
        pollingTask?.cancel()
        isWaitingForTelegram = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
