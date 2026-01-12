import SwiftUI

// MARK: - Profile Screen

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var notificationService = NotificationService.shared
    @State private var showLogin = false
    @State private var showAddresses = false
    @State private var showOrders = false
    @State private var showPersonalData = false
    @State private var showBankCards = false
    @State private var showNotifications = false

    private var isLoggedIn: Bool { appState.isLoggedIn }
    private var userName: String { appState.user?.name?.isEmpty == false ? (appState.user?.name ?? "") : "Профиль" }
    private var phone: String { appState.user?.phone ?? "" }

    private var loyaltyInfo: LoyaltyInfoDTO? { appState.loyaltyInfo }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        
                        if isLoggedIn {
                            promoBanner
                        }
                        
                        bonusCard
                        
                        if isLoggedIn, let info = loyaltyInfo {
                            statsCard(info: info)
                        }
                        
                        if !isLoggedIn {
                            loginCallout
                        }
                        
                        menuList
                        
                        if isLoggedIn {
                            logoutRow
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLogin) {
                LoginView()
            }
            .sheet(isPresented: $showAddresses) {
                AddressSelectionView()
            }
            .sheet(isPresented: $showOrders) {
                MyOrdersView()
            }
            .sheet(isPresented: $showPersonalData) {
                PersonalDataView()
            }
            .sheet(isPresented: $showBankCards) {
                BankCardsView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .task {
                if isLoggedIn && loyaltyInfo == nil {
                    await appState.fetchLoyaltyInfo()
                }
                // Fetch unread notifications count
                if isLoggedIn {
                    try? await notificationService.fetchUnreadCount()
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                if !phone.isEmpty {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isLoggedIn {
                Button {
                    showNotifications = true
                } label: {
                    NotificationBell(badge: notificationService.unreadCount)
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Promo Banner
    private var promoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .padding(10)
                .background(Color.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Клубника в шоколаде🍓")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Промокод MAMA25 на скидку 500 руб. на самовывоз ко Дню матери💕")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Bonus Card
    private var bonusCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(
                    colors: [Color(red: 1.0, green: 0.9, blue: 0.65), Color(red: 1.0, green: 0.85, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Бонусная карта")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Text("\(appState.bonusBalance)")
                                .font(.title)
                                .fontWeight(.bold)
                            Image(systemName: "creditcard.circle.fill")
                                .foregroundColor(.gray)
                        }
                        if let info = loyaltyInfo, info.points_spent > 0 {
                            Text("Потрачено: \(Int(info.points_spent))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }

                Spacer()

                HStack {
                    Text("5%")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                    Text("Кэшбэк")
                        .font(.headline)
                }
                .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(20)
            
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                    .padding(12)
            }
        }
    }
    
    // MARK: - Stats Card
    private func statsCard(info: LoyaltyInfoDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Заказов")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(info.orders_count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Сумма покупок")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(info.orders_sum)) ₽")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()
            }

            if let firstOrderDate = info.first_order_date {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Клиент с \(formatDate(firstOrderDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d MMMM yyyy"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        }
        return dateString
    }
    
    // MARK: - Login Callout
    private var loginCallout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Получать бонусы и скидки")
                .font(.title)
                .fontWeight(.bold)
            Text("Авторизуйтесь, чтобы копить и использовать баллы")
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: { showLogin = true }) {
                Text("Войти")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(14)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Menu
    private var menuList: some View {
        VStack(spacing: 0) {
            Group {
                ProfileMenuRow(icon: "bag", title: "Мои заказы", isEnabled: isLoggedIn) {
                    showOrders = true
                }
                divider
                ProfileMenuRow(icon: "bookmark", title: "Мои адреса", isEnabled: isLoggedIn) {
                    showAddresses = true
                }
                divider
                ProfileMenuRow(icon: "person", title: "Мои данные", isEnabled: isLoggedIn) {
                    showPersonalData = true
                }
                divider
                ProfileMenuRow(icon: "creditcard", title: "Банковские карты", isEnabled: isLoggedIn) {
                    showBankCards = true
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Logout
    private var logoutRow: some View {
        Button(action: appState.logout) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.backward.square")
                    .font(.body)
                Text("Выйти")
                    .font(.body)
                Spacer()
            }
            .foregroundColor(.primary)
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var divider: some View {
        Divider().padding(.leading, 44)
    }
}

// MARK: - Components

private struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 24)
                Text(title)
                    .font(.body)
                Spacer()
            }
            .foregroundColor(isEnabled ? .primary : .secondary)
            .opacity(isEnabled ? 1 : 0.5)
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct NotificationBell: View {
    var badge: Int?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.title3)
                .foregroundColor(.primary)

            if let badge, badge > 0 {
                Text("\(badge)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - My Orders View

struct MyOrdersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [OrderDTO] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let orderService = OrderService()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Загрузка...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Повторить") {
                            Task { await loadOrders() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if orders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bag")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("У вас пока нет заказов")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Ваши заказы появятся здесь после оформления")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(orders) { order in
                                OrderCard(order: order)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Мои заказы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .task {
                await loadOrders()
            }
        }
    }

    private func loadOrders() async {
        isLoading = true
        errorMessage = nil
        do {
            orders = try await orderService.listOrders()
        } catch {
            errorMessage = "Не удалось загрузить заказы"
            print("Failed to load orders: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Order Card

private struct OrderCard: View {
    let order: OrderDTO

    private var statusText: String {
        switch order.status {
        case "new": return "Новый"
        case "pending_payment": return "Ожидает оплаты"
        case "paid": return "Оплачен"
        case "confirmed": return "Подтверждён"
        case "preparing": return "Готовится"
        case "ready": return "Готов"
        case "delivering": return "Доставляется"
        case "completed": return "Выполнен"
        case "cancelled": return "Отменён"
        default: return order.status
        }
    }

    private var statusColor: Color {
        switch order.status {
        case "completed": return .green
        case "cancelled": return .red
        case "pending_payment": return .orange
        case "delivering", "preparing", "ready": return .blue
        default: return .secondary
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: String(order.created_at.prefix(19))) {
            formatter.dateFormat = "d MMM, HH:mm"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        }
        return order.created_at
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Заказ #\(order.id)")
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
            }

            HStack {
                Image(systemName: order.delivery_type == "delivery" ? "bicycle" : "bag")
                    .foregroundColor(.secondary)
                Text(order.delivery_type == "delivery" ? "Доставка" : "Самовывоз")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let address = order.address_text {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Divider()

            HStack {
                if let items = order.items {
                    Text("\(items.count) товар(ов)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(order.total)) ₽")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Personal Data View

struct PersonalDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private var hasChanges: Bool {
        name != (appState.user?.name ?? "") || email != (appState.user?.email ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Личные данные") {
                    HStack {
                        Text("Телефон")
                        Spacer()
                        Text(appState.user?.phone ?? "")
                            .foregroundColor(.secondary)
                    }

                    TextField("Имя", text: $name)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Сохранить")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || !hasChanges)
                    .foregroundColor(.white)
                    .listRowBackground(hasChanges ? Color.red : Color.gray)
                }
            }
            .navigationTitle("Мои данные")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .onAppear {
                name = appState.user?.name ?? ""
                email = appState.user?.email ?? ""
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Сохранено", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Данные успешно обновлены")
            }
        }
    }

    private func saveProfile() async {
        isSaving = true
        do {
            let updatedUser: UserDTO = try await APIClient.shared.request(
                ["me"],
                method: "PATCH",
                body: try JSONEncoder().encode(UserUpdateRequest(name: name, email: email.isEmpty ? nil : email))
            )
            await MainActor.run {
                appState.user = updatedUser
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Не удалось сохранить данные"
                showError = true
            }
            print("Failed to update profile: \(error)")
        }
        isSaving = false
    }
}

// MARK: - User Update Request

private struct UserUpdateRequest: Codable {
    let name: String?
    let email: String?
}

// MARK: - Bank Cards View

struct BankCardsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 70))
                    .foregroundColor(.gray.opacity(0.4))

                VStack(spacing: 8) {
                    Text("Скоро здесь появятся карты")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Функция сохранения банковских карт для быстрой оплаты появится в ближайшем обновлении")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Info card
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Безопасная оплата")
                            .font(.subheadline)
                        Text("Данные карт защищены эквайрингом ВТБ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Банковские карты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

