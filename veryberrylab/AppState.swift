import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: - Auth
    @Published var token: String? {
        didSet {
            APIClient.shared.setToken(token)
            // Сохраняем токен
            if let token = token {
                UserDefaults.standard.set(token, forKey: authTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: authTokenKey)
            }
        }
    }
    @Published var user: UserDTO? {
        didSet {
            // Сохраняем данные пользователя
            if let user = user, let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: authUserKey)
            } else {
                UserDefaults.standard.removeObject(forKey: authUserKey)
            }
        }
    }

    // MARK: - Delivery
    @Published var deliveryType: DeliveryType = .delivery
    @Published var savedAddresses: [DeliveryAddress] = []
    @Published var selectedAddress: DeliveryAddress?
    @Published var pickupLocations: [PickupPoint] = []
    @Published var selectedPickupPoint: PickupPoint?
    @Published var selectedTimeSlot: DeliveryTimeSlot = .asap
    @Published var selectedCity: String = "Москва"
    
    // MARK: - Delivery Info (from server)
    @Published var deliveryFee: Double = 700.0
    @Published var deliverySLAMinutes: Int = 180
    @Published var minOrderTotal: Double?
    @Published var isDeliveryAvailable: Bool = true
    @Published var isCheckingDelivery: Bool = false
    
    // MARK: - Bonus
    @Published var bonusBalance: Int = 0
    @Published var loyaltyInfo: LoyaltyInfoDTO?
    
    private let authService = AuthService()
    let catalogService = CatalogService()
    private let addressesKey = "savedAddresses_v2"
    private let authTokenKey = "auth_token"
    private let authUserKey = "auth_user"
    
    var isLoggedIn: Bool {
        token != nil && user != nil
    }
    
    var currentDeliveryAddress: String {
        switch deliveryType {
        case .delivery:
            return selectedAddress?.shortAddress ?? "Выберите адрес"
        case .pickup:
            return selectedPickupPoint?.displayName ?? "Выберите пункт"
        }
    }
    
    var hasSelectedAddress: Bool {
        switch deliveryType {
        case .delivery:
            return selectedAddress != nil
        case .pickup:
            return selectedPickupPoint != nil
        }
    }
    
    var deliveryTimeText: String {
        "В течение \(deliverySLAMinutes) мин"
    }
    
    init() {
        // Загружаем сохранённую сессию
        loadSavedAuth()
        loadSavedAddresses()

        // Load pickup locations
        Task {
            await loadPickupLocations()
        }
        // Check delivery for initial address
        if let address = selectedAddress {
            Task {
                await checkDeliveryForAddress(address)
            }
        }
        // Обновляем данные лояльности если залогинены
        if isLoggedIn {
            Task {
                await fetchLoyaltyInfo()
            }
        }
    }
    
    // MARK: - Auth Methods

    private func loadSavedAuth() {
        // Загружаем токен
        if let savedToken = UserDefaults.standard.string(forKey: authTokenKey) {
            // Устанавливаем токен напрямую без вызова didSet (чтобы не перезаписывать)
            _token = Published(initialValue: savedToken)
            APIClient.shared.setToken(savedToken)
        }

        // Загружаем данные пользователя
        if let userData = UserDefaults.standard.data(forKey: authUserKey),
           let savedUser = try? JSONDecoder().decode(UserDTO.self, from: userData) {
            _user = Published(initialValue: savedUser)
        }
    }

    func setAuthData(token: String, user: UserDTO) async {
        self.token = token
        self.user = user
        await fetchLoyaltyInfo()
    }

    func logout() {
        token = nil
        user = nil
        bonusBalance = 0
        loyaltyInfo = nil
    }
    
    func fetchLoyaltyInfo() async {
        guard isLoggedIn else { return }
        do {
            let info: LoyaltyInfoDTO = try await APIClient.shared.request(["me", "loyalty"])
            loyaltyInfo = info
            bonusBalance = Int(info.points_available)
        } catch {
            print("Failed to fetch loyalty info: \(error)")
        }
    }
    
    // MARK: - Address Methods
    
    func addAddress(_ address: DeliveryAddress) {
        var newAddress = address
        // Если это первый адрес, сделать его по умолчанию
        if savedAddresses.isEmpty {
            newAddress = DeliveryAddress(
                id: address.id,
                street: address.street,
                building: address.building,
                apartment: address.apartment,
                entrance: address.entrance,
                floor: address.floor,
                intercom: address.intercom,
                comment: address.comment,
                latitude: address.latitude,
                longitude: address.longitude,
                isDefault: true,
                isPrivateHouse: address.isPrivateHouse
            )
        }
        savedAddresses.append(newAddress)
        saveAddresses()
        
        // Автоматически выбрать новый адрес и проверить доставку
        selectAddress(newAddress)
    }
    
    func removeAddress(_ address: DeliveryAddress) {
        savedAddresses.removeAll { $0.id == address.id }
        if selectedAddress?.id == address.id {
            if let first = savedAddresses.first {
                selectAddress(first)
            } else {
                selectedAddress = nil
                deliveryFee = 700.0
                deliverySLAMinutes = 180
            }
        }
        saveAddresses()
    }
    
    func selectAddress(_ address: DeliveryAddress) {
        selectedAddress = address
        Task {
            await checkDeliveryForAddress(address)
        }
    }
    
    func setDefaultAddress(_ address: DeliveryAddress) {
        for i in savedAddresses.indices {
            let current = savedAddresses[i]
            savedAddresses[i] = DeliveryAddress(
                id: current.id,
                street: current.street,
                building: current.building,
                apartment: current.apartment,
                entrance: current.entrance,
                floor: current.floor,
                intercom: current.intercom,
                comment: current.comment,
                latitude: current.latitude,
                longitude: current.longitude,
                isDefault: current.id == address.id,
                isPrivateHouse: current.isPrivateHouse
            )
        }
        saveAddresses()
    }
    
    // MARK: - Delivery Check
    
    func checkDeliveryForAddress(_ address: DeliveryAddress) async {
        guard let lat = address.latitude, let lng = address.longitude else {
            // No coordinates, use default
            deliveryFee = 700.0
            deliverySLAMinutes = 180
            isDeliveryAvailable = true
            return
        }
        
        isCheckingDelivery = true
        
        do {
            let response = try await catalogService.checkDelivery(lat: lat, lng: lng, city: selectedCity)
            deliveryFee = response.delivery_fee
            deliverySLAMinutes = response.sla_minutes
            minOrderTotal = response.min_order_total
            isDeliveryAvailable = response.available
            
            // Update time slot text
            selectedTimeSlot = DeliveryTimeSlot(
                title: "Как можно скорее",
                subtitle: "В течение \(response.sla_minutes) мин",
                minutesFromNow: response.sla_minutes
            )
        } catch {
            // On error, use defaults
            print("Delivery check error: \(error)")
            deliveryFee = 700.0
            deliverySLAMinutes = 180
            isDeliveryAvailable = true
        }
        
        isCheckingDelivery = false
    }
    
    // MARK: - Time Slot Methods
    
    func selectTimeSlot(_ slot: DeliveryTimeSlot) {
        selectedTimeSlot = slot
    }

    // MARK: - Pickup Locations

    func loadPickupLocations() async {
        do {
            let locations = try await catalogService.fetchPickupLocations()
            pickupLocations = locations.filter { $0.isActive }.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            print("Failed to load pickup locations: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadSavedAddresses() {
        guard let data = UserDefaults.standard.data(forKey: addressesKey),
              let addresses = try? JSONDecoder().decode([DeliveryAddress].self, from: data),
              !addresses.isEmpty else {
            // Новый аккаунт - без адресов
            savedAddresses = []
            selectedAddress = nil
            return
        }
        savedAddresses = addresses
        selectedAddress = addresses.first { $0.isDefault } ?? addresses.first
    }
    
    private func saveAddresses() {
        guard let data = try? JSONEncoder().encode(savedAddresses) else { return }
        UserDefaults.standard.set(data, forKey: addressesKey)
    }
}
