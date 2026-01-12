import SwiftUI

struct ProductDetailView: View {
    let productId: Int
    @EnvironmentObject var cartVM: CartViewModel
    @StateObject private var vm = ProductDetailViewModel()
    @State private var showFullDescription = false
    @State private var showCart = false
    @Environment(\.dismiss) private var dismiss
    
    private var currentCartItem: CartItem? {
        let opts = vm.selectionForCart()
        return cartVM.cartItem(forProductId: productId, options: opts)
    }
    
    private var quantityInCart: Int {
        currentCartItem?.quantity ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if let product = vm.product {
                    VStack(alignment: .leading, spacing: 0) {
                        // Product Image
                        ProductImageSection(product: product)
                        
                        // Product Info
                        VStack(alignment: .leading, spacing: 16) {
                            // Name
                            Text(product.name ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // Description
                            if let desc = product.description, !desc.isEmpty {
                                DescriptionSection(
                                    text: desc,
                                    isExpanded: $showFullDescription
                                )
                            }
                            
                            // Modification Groups
                            ForEach(product.modification_groups ?? []) { group in
                                ModificationGroupSection(
                                    group: group,
                                    vm: vm
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 120) // Space for bottom bar
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            // Bottom Bar
            if vm.product != nil {
                BottomPriceBar(
                    unitPrice: vm.unitPrice,
                    quantityInCart: quantityInCart,
                    onDecrement: {
                        let opts = vm.selectionForCart()
                        cartVM.decrementProduct(productId, options: opts)
                    },
                    onIncrement: {
                        let opts = vm.selectionForCart()
                        if let product = vm.product {
                            cartVM.add(product: product, options: opts)
                        }
                    },
                    onOpenCart: {
                        showCart = true
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Empty to hide title
                Text("")
            }
        }
        .overlay {
            if vm.loading {
                ProgressView()
            }
        }
        .alert(isPresented: Binding(get: { vm.error != nil }, set: { _ in vm.error = nil })) {
            Alert(title: Text("Ошибка"), message: Text(vm.error ?? ""), dismissButton: .default(Text("OK")))
        }
        .task {
            await vm.load(productId: productId)
        }
        .sheet(isPresented: $showCart) {
            CartSheetView()
        }
    }
}

// MARK: - Product Image Section
private struct ProductImageSection: View {
    let product: ProductDTO
    
    private var productImageURL: URL? {
        guard let urlString = product.media?.first,
              let url = URL(string: urlString) else { return nil }
        
        // If backend stored localhost (dev), rewrite to current API host keeping the path.
        if let host = url.host, host == "localhost" || host == "127.0.0.1" {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.scheme = AppConfig.apiBaseURL.scheme
            comps?.host = AppConfig.apiBaseURL.host
            comps?.port = AppConfig.apiBaseURL.port
            return comps?.url ?? url
        }
        return url
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let url = productImageURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                        .cornerRadius(16)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(ProgressView())
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Description Section
private struct DescriptionSection: View {
    let text: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)

                if !isExpanded && text.count > 80 {
                    Button("больше") {
                        withAnimation {
                            isExpanded = true
                        }
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Modification Group Section
private struct ModificationGroupSection: View {
    let group: ModificationGroupDTO
    @ObservedObject var vm: ProductDetailViewModel
    
    private var hasImageOptions: Bool {
        (group.options ?? []).contains { $0.image_url != nil && !($0.image_url?.isEmpty ?? true) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name ?? "")
                    .font(.title3)

                if let minCount = group.min_count, minCount > 0 {
                    Text("Минимум: \(minCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Options
            if hasImageOptions {
                // Grid layout for image options
                ImageOptionsGrid(group: group, vm: vm)
            } else {
                // List layout for text options
                TextOptionsList(group: group, vm: vm)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Image Options Grid
private struct ImageOptionsGrid: View {
    let group: ModificationGroupDTO
    @ObservedObject var vm: ProductDetailViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(group.options ?? []) { option in
                ImageOptionCard(
                    option: option,
                    isSelected: vm.isOptionSelected(group: group, option: option),
                    onTap: { vm.toggleOption(group: group, option: option) }
                )
            }
        }
    }
}

// MARK: - Image Option Card
private struct ImageOptionCard: View {
    let option: ModificationOptionDTO
    let isSelected: Bool
    let onTap: () -> Void
    
    private var optionImageURL: URL? {
        guard let raw = option.image_url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        
        // Absolute URL
        if let absolute = URL(string: raw), absolute.scheme != nil {
            // If backend stored localhost (dev), rewrite to current API host keeping the path.
            if let host = absolute.host, host == "localhost" || host == "127.0.0.1" {
                var comps = URLComponents(url: absolute, resolvingAgainstBaseURL: false)
                comps?.scheme = AppConfig.apiBaseURL.scheme
                comps?.host = AppConfig.apiBaseURL.host
                comps?.port = AppConfig.apiBaseURL.port
                return comps?.url ?? absolute
            }
            return absolute
        }
        
        // Relative URL (e.g. /uploads/...)
        return URL(string: raw, relativeTo: AppConfig.apiBaseURL)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.08))
                    
                    if let url = optionImageURL {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
                )
                
                // Name
                Text(option.name ?? "")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Price
                if let price = option.extra_price, price > 0 {
                    Text("+ \(Int(price)) ₽")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Options List
private struct TextOptionsList: View {
    let group: ModificationGroupDTO
    @ObservedObject var vm: ProductDetailViewModel
    
    private var isSingle: Bool {
        (group.type ?? "single") == "single"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(group.options ?? []) { option in
                TextOptionRow(
                    option: option,
                    isSingle: isSingle,
                    isSelected: vm.isOptionSelected(group: group, option: option),
                    onTap: { vm.toggleOption(group: group, option: option) }
                )
            }
        }
    }
}

// MARK: - Text Option Row
private struct TextOptionRow: View {
    let option: ModificationOptionDTO
    let isSingle: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Name and price
                HStack(spacing: 4) {
                    Text(option.name ?? "")
                        .font(.body)
                        .foregroundColor(.primary)

                    if let price = option.extra_price, price > 0 {
                        Text("+\(Int(price)) ₽")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSingle {
                    Circle()
                        .stroke(isSelected ? Color.red : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(isSelected ? Color.red : Color.clear)
                                .frame(width: 12, height: 12)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.red : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1 : 0)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Color.red : Color.clear)
                        )
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Price Bar
private struct BottomPriceBar: View {
    let unitPrice: Double
    let quantityInCart: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onOpenCart: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                if quantityInCart == 0 {
                    // Initial state: Red button with "PRICE ₽ +"
                    Button(action: onIncrement) {
                        HStack(spacing: 8) {
                            Text("\(Int(unitPrice)) ₽")
                                .font(.title3)
                                .fontWeight(.bold)
                            Image(systemName: "plus")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(14)
                    }
                } else {
                    // In cart state: "− quantity × PRICE ₽ +" + cart icon
                    HStack(spacing: 0) {
                        Button(action: onDecrement) {
                            Image(systemName: "minus")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(width: 50, height: 56)
                        }

                        Text("\(quantityInCart) × \(Int(unitPrice)) ₽")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: onIncrement) {
                            Image(systemName: "plus")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(width: 50, height: 56)
                        }
                    }
                    .background(Color.red)
                    .cornerRadius(14)
                    
                    // Cart icon button
                    Button(action: onOpenCart) {
                        Image(systemName: "bag.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 56, height: 56)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    NavigationView {
        ProductDetailView(productId: 1)
            .environmentObject(CartViewModel())
    }
}
