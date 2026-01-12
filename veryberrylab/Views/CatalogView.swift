import SwiftUI
import UIKit

struct CatalogView: View {
    @EnvironmentObject var catalogVM: CatalogViewModel
    @EnvironmentObject var cartVM: CartViewModel
    @EnvironmentObject var appState: AppState
    @State private var showCart = false
    @State private var showAddressSelection = false
    @State private var showLogin = false
    @State private var error: String?
    @State private var showStickyCategories = false
    @State private var categoriesMinY: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                GeometryReader { outerGeo in
                    let safeTop = outerGeo.safeAreaInsets.top

                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Delivery Header
                                DeliveryHeaderSection(
                                    deliveryType: appState.deliveryType,
                                    address: appState.currentDeliveryAddress,
                                    onTap: { showAddressSelection = true }
                                )

                                // Auth Banner (for non-logged in users)
                                if !appState.isLoggedIn {
                                    AuthBannerView(onTap: { showLogin = true })
                                }

                                // Promo Banners
                                BannersSection(banners: catalogVM.banners)

                                // Categories with anchor scrolling
                                CategoriesSection(
                                    categories: sortedCategories,
                                    selected: catalogVM.selectedCategory,
                                    onSelect: { id in
                                        catalogVM.selectCategory(id: id)
                                        scrollToCategory(id, proxy: proxy)
                                    }
                                )
                                .background(
                                    GeometryReader { categoryGeo -> Color in
                                        let minY = categoryGeo.frame(in: .global).minY
                                        DispatchQueue.main.async {
                                            self.categoriesMinY = minY
                                            self.showStickyCategories = minY < safeTop
                                        }
                                        return Color.clear
                                    }
                                )

                                LazyVStack(alignment: .leading, spacing: 24) {
                                    ForEach(categorySections()) { section in
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(section.name)
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 4)
                                            
                                            if section.products.isEmpty {
                                                Text("Нет товаров в этой категории")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 4)
                                            } else {
                                                LazyVGrid(columns: gridColumns(for: outerGeo.size.width), spacing: cardSpacing) {
                                                    ForEach(section.products) { product in
                                                        ProductCard(product: product)
                                                    }
                                                }
                                            }
                                        }
                                        .id(section.anchorId)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, cartVM.items.isEmpty ? 16 : 120)
                        }

                        // Persistent cart bar
                        if !cartVM.items.isEmpty {
                            FloatingCartButton(
                                itemsCount: cartVM.itemsCount,
                                total: cartVM.subtotal,
                                onTap: { showCart = true }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .onChange(of: catalogVM.selectedCategory) { oldValue, newValue in
                        guard let newValue else { return }
                        scrollToCategory(newValue, proxy: proxy)
                    }
                }
            }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top, spacing: 0) {
                if showStickyCategories {
                    VStack(spacing: 0) {
                        CategoriesSection(
                            categories: sortedCategories,
                            selected: catalogVM.selectedCategory,
                            onSelect: { id in
                                catalogVM.selectCategory(id: id)
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        Divider()
                    }
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showStickyCategories)
            .overlay {
                if catalogVM.loading {
                    ProgressView()
                }
            }
            .alert(isPresented: Binding(get: { catalogVM.error != nil }, set: { _ in catalogVM.error = nil })) {
                Alert(title: Text("Ошибка"), message: Text(catalogVM.error ?? ""), dismissButton: .default(Text("OK")))
            }
            .task {
                await catalogVM.loadAll()
            }
            .sheet(isPresented: $showCart) {
                CartSheetView()
            }
            .sheet(isPresented: $showAddressSelection) {
                AddressSelectionView()
            }
            .sheet(isPresented: $showLogin) {
                LoginView()
            }
        }
    }
    
    private let cardSpacing: CGFloat = 10
    
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let outerHPad: CGFloat = 16
        let cardWidth = floor((width - outerHPad * 2 - cardSpacing) / 2)
        return [
            GridItem(.fixed(cardWidth), spacing: cardSpacing),
            GridItem(.fixed(cardWidth), spacing: cardSpacing)
        ]
    }
    
    private var sortedCategories: [CategoryDTO] {
        catalogVM.categories.sorted {
            let left = ($0.sort_order ?? Int.max, $0.id ?? Int.max)
            let right = ($1.sort_order ?? Int.max, $1.id ?? Int.max)
            return left < right
        }
    }
    
    private func categorySections() -> [CategorySectionModel] {
        var sections: [CategorySectionModel] = []
        
        for category in sortedCategories {
            let productsForCategory = catalogVM.products.filter { $0.category_id == category.id }
            let categoryName = category.name ?? "Категория"
            sections.append(CategorySectionModel(categoryId: category.id, name: categoryName, products: productsForCategory))
        }
        
        let uncategorizedProducts = catalogVM.products.filter { product in
            guard let cid = product.category_id else { return true }
            return !sortedCategories.contains(where: { $0.id == cid })
        }
        if !uncategorizedProducts.isEmpty {
            sections.append(CategorySectionModel(categoryId: nil, name: "Без категории", products: uncategorizedProducts))
        }
        
        return sections
    }
    
    private func anchorId(for categoryId: Int?) -> String {
        "category-\(categoryId.map(String.init) ?? "none")"
    }
    
    private func scrollToCategory(_ id: Int?, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut) {
            proxy.scrollTo(anchorId(for: id), anchor: .top)
        }
    }
}

private struct CategorySectionModel: Identifiable {
    let categoryId: Int?
    let name: String
    let products: [ProductDTO]
    
    var id: String { anchorId }
    var anchorId: String { "category-\(categoryId.map(String.init) ?? "none")" }
}

// MARK: - Delivery Header

private struct DeliveryHeaderSection: View {
    let deliveryType: DeliveryType
    let address: String
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Delivery Type Selector
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Text(deliveryType.title)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            
            // Delivery Info
            Text("Доставим из VeryBerryLab - Москва")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Address
            Button(action: onTap) {
                Text(address)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// MARK: - Auth Banner

private struct AuthBannerView: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 44, height: 44)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Получать бонусы и скидки")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Text("Авторизуйтесь, чтобы копить и использовать баллы")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.black.opacity(0.5))
            }
            .padding(16)
            .background(Color.yellow)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Cart Button

private struct FloatingCartButton: View {
    let itemsCount: Int
    let total: Double
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text("Корзина")
                    .font(.headline)

                Spacer()

                Text("\(Int(total)) ₽")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Banners Section

private struct BannersSection: View {
    let banners: [BannerDTO]
    var body: some View {
        if !banners.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(banners) { banner in
                        BannerCard(banner: banner)
                            .frame(width: 180, height: 200)
                    }
                }
                .padding(.leading, 12) // nudge banners slightly right
            }
        }
    }
}

// MARK: - Categories Section

private struct CategoriesSection: View {
    let categories: [CategoryDTO]
    let selected: Int?
    var onSelect: (Int?) -> Void
    
    var body: some View {
        if !categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(categories) { cat in
                        let cid = cat.id
                        let isSelected = cid == selected || (selected == nil && cat.id == categories.first?.id)
                        Button {
                            onSelect(cid)
                        } label: {
                            Text(cat.name ?? "")
                                .font(isSelected ? .callout : .subheadline)
                                .fontWeight(isSelected ? .bold : .medium)
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color(.systemGray5) : Color.clear)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Banner Card

private struct BannerCard: View {
    let banner: BannerDTO
    
    private var bannerImageURL: URL? {
        guard let raw = banner.image_url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        
        if let absolute = URL(string: raw), absolute.scheme != nil {
            if let host = absolute.host, host == "localhost" || host == "127.0.0.1" {
                var comps = URLComponents(url: absolute, resolvingAgainstBaseURL: false)
                comps?.scheme = AppConfig.apiBaseURL.scheme
                comps?.host = AppConfig.apiBaseURL.host
                comps?.port = AppConfig.apiBaseURL.port
                return comps?.url ?? absolute
            }
            return absolute
        }
        
        return URL(string: raw, relativeTo: AppConfig.apiBaseURL)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = bannerImageURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.12)
                        .overlay { ProgressView() }
                }
            } else {
                Color.red.opacity(0.9)
            }

            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title ?? "")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(radius: 2)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .cornerRadius(16)
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    @EnvironmentObject var cartVM: CartViewModel
    let product: ProductDTO
    
    private var productImageURL: URL? {
        guard let urlString = product.media?.first,
              let url = URL(string: urlString) else { return nil }
        
        if let host = url.host, host == "localhost" || host == "127.0.0.1" {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.scheme = AppConfig.apiBaseURL.scheme
            comps?.host = AppConfig.apiBaseURL.host
            comps?.port = AppConfig.apiBaseURL.port
            return comps?.url ?? url
        }
        return url
    }
    
    private var quantityInCart: Int {
        cartVM.totalQuantity(forProductId: product.id ?? 0)
    }
    
    // Get all cart items for this product (to decrement the first one)
    private var firstCartItem: CartItem? {
        cartVM.items.first { $0.productId == product.id ?? 0 }
    }
    
    private var descriptionText: String? {
        let text = (product.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Product Image - tappable to open detail
            NavigationLink(destination: ProductDetailView(productId: product.id ?? 0)) {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.08))
                        if let url = productImageURL {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
                    .cornerRadius(14)
                }
                .aspectRatio(1, contentMode: .fit)
            }
            .buttonStyle(.plain)
            
            // Product Name - tappable to open detail
            NavigationLink(destination: ProductDetailView(productId: product.id ?? 0)) {
                Text(product.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .buttonStyle(.plain)

            // Description with fixed height for consistent card layout
            Text(descriptionText ?? " ")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(minHeight: 20, alignment: .topLeading)

            // Control or Price Pill
            if quantityInCart > 0 {
                CatalogQuantityControl(
                    quantity: quantityInCart,
                    onDecrement: {
                        if let item = firstCartItem {
                            cartVM.decrement(item)
                        }
                    },
                    onIncrement: {
                        cartVM.add(product: product, options: [])
                    }
                )
            } else {
                NavigationLink(destination: ProductDetailView(productId: product.id ?? 0)) {
                    PricePill(price: product.base_price ?? 0)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white)
    }
}

private struct CatalogQuantityControl: View {
    let quantity: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            
            Text("\(quantity)")
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(minWidth: 24)
            
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

private struct PricePill: View {
    let price: Double

    var body: some View {
        HStack(spacing: 6) {
            Text("от \(Int(price)) ₽")
                .font(.subheadline)
                .fontWeight(.bold)
            Image(systemName: "chevron.right")
                .font(.footnote)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - Category Offset Preference Key

private struct CategoryOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
