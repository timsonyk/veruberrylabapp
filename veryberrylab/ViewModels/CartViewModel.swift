import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var promoCode: String = ""
    @Published var appliedPromo: PromoCode?
    @Published var orderComment: String = ""
    @Published var doNotCall: Bool = false
    @Published var isApplyingPromo: Bool = false
    @Published var promoError: String?
    
    // Cashback percentage (could come from server)
    private let cashbackPercentage: Double = 5.0
    
    var itemsCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var promoDiscount: Double {
        appliedPromo?.calculateDiscount(for: subtotal) ?? 0
    }
    
    var deliveryFee: Double {
        items.isEmpty ? 0 : 700
    }
    
    var total: Double {
        max(0, subtotal - promoDiscount + deliveryFee)
    }
    
    var earnedBonuses: Int {
        Int(subtotal * cashbackPercentage / 100)
    }
    
    func add(product: ProductDTO, options: [SelectedOption]) {
        let pid = product.id ?? 0
        if let idx = items.firstIndex(where: { $0.productId == pid && $0.selectedOptions == options }) {
            items[idx].quantity += 1
        } else {
            let item = CartItem(
                productId: pid,
                name: product.name ?? "",
                basePrice: product.base_price ?? 0,
                media: product.media,
                quantity: 1,
                selectedOptions: options
            )
            items.append(item)
        }
    }
    
    func increment(_ item: CartItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        items[idx].quantity += 1
    }
    
    func decrement(_ item: CartItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        if items[idx].quantity > 1 {
            items[idx].quantity -= 1
        } else {
            items.remove(at: idx)
        }
    }
    
    func remove(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    // MARK: - Helper Methods for Product Quantity
    
    /// Returns the total quantity of a product in cart (across all option variations)
    func totalQuantity(forProductId productId: Int) -> Int {
        items.filter { $0.productId == productId }.reduce(0) { $0 + $1.quantity }
    }
    
    /// Returns the cart item for specific product and options combination
    func cartItem(forProductId productId: Int, options: [SelectedOption]) -> CartItem? {
        items.first { $0.productId == productId && $0.selectedOptions == options }
    }
    
    /// Increments quantity for specific product+options
    func incrementProduct(_ productId: Int, options: [SelectedOption]) {
        if let idx = items.firstIndex(where: { $0.productId == productId && $0.selectedOptions == options }) {
            items[idx].quantity += 1
        }
    }
    
    /// Decrements quantity for specific product+options
    func decrementProduct(_ productId: Int, options: [SelectedOption]) {
        if let idx = items.firstIndex(where: { $0.productId == productId && $0.selectedOptions == options }) {
            if items[idx].quantity > 1 {
                items[idx].quantity -= 1
            } else {
                items.remove(at: idx)
            }
        }
    }
    
    func clearCart() {
        items.removeAll()
        appliedPromo = nil
        promoCode = ""
        orderComment = ""
        doNotCall = false
    }
    
    // MARK: - Promo Code
    
    func applyPromoCode() async {
        guard !promoCode.isEmpty else { return }
        
        isApplyingPromo = true
        promoError = nil
        
        // TODO: Replace with actual API call
        // Simulating API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Demo promo codes
        if promoCode.uppercased() == "SALE10" {
            appliedPromo = PromoCode(
                code: promoCode.uppercased(),
                discountType: .percentage,
                discountValue: 10,
                minOrderAmount: 1000,
                maxDiscount: 1000,
                isActive: true
            )
        } else if promoCode.uppercased() == "FIRST500" {
            appliedPromo = PromoCode(
                code: promoCode.uppercased(),
                discountType: .fixed,
                discountValue: 500,
                minOrderAmount: 3000,
                maxDiscount: nil,
                isActive: true
            )
        } else {
            promoError = "Промокод не найден"
            appliedPromo = nil
        }
        
        isApplyingPromo = false
    }
    
    func removePromoCode() {
        appliedPromo = nil
        promoCode = ""
        promoError = nil
    }
    
    // MARK: - Recommendations
    
    func getRecommendations() -> [ProductDTO] {
        // TODO: Fetch from API
        return []
    }
}
