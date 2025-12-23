import SwiftUI

// MARK: - Profile Screen

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showAddresses = false
    
    private var isLoggedIn: Bool { appState.isLoggedIn }
    private var userName: String { appState.user?.name?.isEmpty == false ? (appState.user?.name ?? "") : "Профиль" }
    private var phone: String { appState.user?.phone ?? "" }
    
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
                        
                        if isLoggedIn {
                            inviteFriendsCard
                        } else {
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
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.largeTitle).bold()
                if !phone.isEmpty {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isLoggedIn {
                NotificationBell(badge: 1)
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
                    .font(.subheadline).bold()
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
                    }
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Text("5%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                    Text("Кэшбэк")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
            }
            .padding(20)
            
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                    .padding(12)
            }
        }
    }
    
    // MARK: - Invite Friends
    private var inviteFriendsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.title2)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Приглашайте друзей")
                    .font(.headline)
                Text("Дарим 0 баллов за каждого друга")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "gift.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Login Callout
    private var loginCallout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Получать бонусы и скидки")
                .font(.system(size: 28, weight: .bold))
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
                ProfileMenuRow(icon: "bag", title: "Мои заказы", isEnabled: isLoggedIn) {}
                divider
                ProfileMenuRow(icon: "bookmark", title: "Мои адреса", isEnabled: isLoggedIn) {
                    showAddresses = true
                }
                divider
                ProfileMenuRow(icon: "person", title: "Мои данные", isEnabled: isLoggedIn) {}
                divider
                ProfileMenuRow(icon: "creditcard", title: "Банковские карты", isEnabled: isLoggedIn) {}
            }
            divider
            ProfileMenuRow(icon: "location", title: appState.selectedCity) {}
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
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

