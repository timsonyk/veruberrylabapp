import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: - Auth
    @Published var token: String? {
        didSet { APIClient.shared.setToken(token) }
    }
    @Published var user: UserDTO?
    
    // MARK: - Delivery
    @Published var deliveryType: DeliveryType = .delivery
    @Published var savedAddresses: [DeliveryAddress] = []
    @Published var selectedAddress: DeliveryAddress?
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
    
    private let authService = AuthService()
    let catalogService = CatalogService()
    private let addressesKey = "savedAddresses_v2"
    
    var isLoggedIn: Bool {
        token != nil && user != nil
    }
    
    var currentDeliveryAddress: String {
        switch deliveryType {
        case .delivery:
            return selectedAddress?.shortAddress ?? "Выберите адрес"
        case .pickup:
            return selectedPickupPoint?.address ?? "Выберите пункт"
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
        loadSavedAddresses()
        // Check delivery for initial address
        if let address = selectedAddress {
            Task {
                await checkDeliveryForAddress(address)
            }
        }
    }
    
    // MARK: - Auth Methods
    
    func login(phone: String, code: String) async throws {
        let resp = try await authService.verify(phone: phone, code: code)
        token = resp.access_token
        user = resp.user
    }
    
    func logout() {
        token = nil
        user = nil
        bonusBalance = 0
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
