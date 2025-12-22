import Foundation

struct SelectedOption: Identifiable, Hashable {
    let id: Int
    let name: String
    let extraPrice: Double
}

struct CartItem: Identifiable, Hashable {
    let id = UUID()
    let productId: Int
    let name: String
    let basePrice: Double
    let media: [String]?
    var quantity: Int
    var selectedOptions: [SelectedOption]
    
    var totalPrice: Double {
        let mods = selectedOptions.reduce(0) { $0 + $1.extraPrice }
        return (basePrice + mods) * Double(quantity)
    }
}

