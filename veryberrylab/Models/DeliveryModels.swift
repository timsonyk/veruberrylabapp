import Foundation
import CoreLocation

// MARK: - Delivery Type

enum DeliveryType: String, CaseIterable, Identifiable {
    case delivery = "delivery"
    case pickup = "pickup"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .delivery: return "Доставка"
        case .pickup: return "Самовывоз"
        }
    }
}

// MARK: - Delivery Address

struct DeliveryAddress: Identifiable, Codable, Hashable {
    let id: UUID
    var street: String
    var building: String?
    var apartment: String?
    var entrance: String?
    var floor: String?
    var intercom: String?
    var comment: String?
    var latitude: Double?
    var longitude: Double?
    var isDefault: Bool
    var isPrivateHouse: Bool
    
    var fullAddress: String {
        var parts = [street]
        if let building = building, !building.isEmpty {
            parts.append(building)
        }
        return parts.joined(separator: ", ")
    }
    
    var shortAddress: String {
        street
    }
    
    /// Returns details like "Подъезд 2, кв. 15, этаж 3" or "Частный дом"
    var detailsText: String? {
        if isPrivateHouse {
            return "Частный дом"
        }
        
        var details: [String] = []
        
        if let entrance = entrance, !entrance.isEmpty {
            details.append("подъезд \(entrance)")
        }
        if let apartment = apartment, !apartment.isEmpty {
            details.append("кв. \(apartment)")
        }
        if let floor = floor, !floor.isEmpty {
            details.append("этаж \(floor)")
        }
        
        return details.isEmpty ? nil : details.joined(separator: ", ")
    }
    
    init(
        id: UUID = UUID(),
        street: String,
        building: String? = nil,
        apartment: String? = nil,
        entrance: String? = nil,
        floor: String? = nil,
        intercom: String? = nil,
        comment: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isDefault: Bool = false,
        isPrivateHouse: Bool = false
    ) {
        self.id = id
        self.street = street
        self.building = building
        self.apartment = apartment
        self.entrance = entrance
        self.floor = floor
        self.intercom = intercom
        self.comment = comment
        self.latitude = latitude
        self.longitude = longitude
        self.isDefault = isDefault
        self.isPrivateHouse = isPrivateHouse
    }
}

// MARK: - Pickup Point

struct PickupPoint: Identifiable, Codable, Hashable {
    let id: Int
    let city: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let workingHours: String?
    let isActive: Bool
    let sortOrder: Int

    var displayName: String {
        "\(city): \(address)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, city, address = "address_text", latitude = "lat", longitude = "lng"
        case phone, workingHours = "working_hours", isActive = "is_active", sortOrder = "sort_order"
    }
}

// MARK: - Delivery Time

struct DeliveryTimeSlot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String?
    let minutesFromNow: Int?
    let specificDate: Date?
    let specificTimeRange: String?
    
    var displayText: String {
        if let minutes = minutesFromNow {
            return "В течение \(minutes) мин"
        } else if let range = specificTimeRange {
            return range
        }
        return title
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        minutesFromNow: Int? = nil,
        specificDate: Date? = nil,
        specificTimeRange: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.minutesFromNow = minutesFromNow
        self.specificDate = specificDate
        self.specificTimeRange = specificTimeRange
    }
    
    // Preset time slots
    static let asap = DeliveryTimeSlot(
        title: "Как можно скорее",
        subtitle: "В течение 180 мин",
        minutesFromNow: 180
    )
    
    static let threeHours = DeliveryTimeSlot(
        title: "3 часа",
        minutesFromNow: 180
    )
}

// MARK: - Promo Code

struct PromoCode: Codable, Hashable {
    let code: String
    let discountType: DiscountType
    let discountValue: Double
    let minOrderAmount: Double?
    let maxDiscount: Double?
    let isActive: Bool
    
    enum DiscountType: String, Codable {
        case percentage
        case fixed
    }
    
    func calculateDiscount(for amount: Double) -> Double {
        guard isActive else { return 0 }
        
        if let minAmount = minOrderAmount, amount < minAmount {
            return 0
        }
        
        var discount: Double
        switch discountType {
        case .percentage:
            discount = amount * (discountValue / 100)
        case .fixed:
            discount = discountValue
        }
        
        if let maxDiscount = maxDiscount {
            discount = min(discount, maxDiscount)
        }
        
        return discount
    }
}

// MARK: - Bonus Info

struct BonusInfo: Codable {
    let currentBalance: Int
    let earnedFromOrder: Int
    let cashbackPercentage: Double
    
    var earnedText: String {
        "+\(earnedFromOrder)"
    }
}

// MARK: - Order Comment

struct OrderOptions {
    var comment: String = ""
    var doNotCall: Bool = false
}
