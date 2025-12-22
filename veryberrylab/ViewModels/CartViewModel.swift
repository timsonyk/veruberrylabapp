import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var deliveryFee: Double {
        items.isEmpty ? 0 : 700
    }
    
    var total: Double {
        subtotal + deliveryFee
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
}

