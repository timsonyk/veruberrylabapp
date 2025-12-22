import SwiftUI

struct ProductDetailView: View {
    let productId: Int
    @EnvironmentObject var cartVM: CartViewModel
    @StateObject private var vm = ProductDetailViewModel()
    @State private var showFullDescription = false
    @Environment(\.dismiss) private var dismiss
    
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
                    quantity: vm.quantity,
                    totalPrice: vm.totalPrice,
                    onDecrement: { vm.decrement() },
                    onIncrement: { vm.increment() },
                    onAddToCart: {
                        for _ in 0..<vm.quantity {
                            let opts = vm.selectionForCart()
                            if let product = vm.product {
                                cartVM.add(product: product, options: opts)
                            }
                        }
                        dismiss()
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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Color.gray.opacity(0.1)
                    }
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
                    .fontWeight(.semibold)
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
                    .fontWeight(.bold)
                
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
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            @unknown default:
                                Color.gray.opacity(0.1)
                            }
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
                        .foregroundColor(.primary)
                    
                    if let price = option.extra_price, price > 0 {
                        Text("+\(Int(price)) ₽")
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
    let quantity: Int
    let totalPrice: Double
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Quantity and Price controls
                HStack(spacing: 0) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }
                    
                    Text("\(quantity) × \(Int(totalPrice)) ₽")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }
                }
                .background(Color(red: 0.2, green: 0.7, blue: 0.5))
                .cornerRadius(14)
                
                // Cart button
                Button(action: onAddToCart) {
                    Image(systemName: "bag.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(14)
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
