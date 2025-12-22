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
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
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
                            
                            LazyVStack(alignment: .leading, spacing: 24) {
                                ForEach(categorySections()) { section in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(section.name)
                                            .font(.title2)
                                            .bold()
                                            .padding(.horizontal, 4)
                                        
                                        if section.products.isEmpty {
                                            Text("Нет товаров в этой категории")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 4)
                                        } else {
                                            LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
                                                ForEach(section.products) { product in
                                                    ProductCard(product: product) {
                                                        cartVM.add(product: product, options: [])
                                                    }
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
                .onChange(of: catalogVM.selectedCategory) { newValue in
                    guard let newValue else { return }
                    scrollToCategory(newValue, proxy: proxy)
                }
            }
            .navigationBarHidden(true)
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
    
    private let cardSpacing: CGFloat = 16
    
    private var cardWidth: CGFloat {
        let horizontalPadding: CGFloat = 32 // matches outer horizontal padding
        let availableWidth = UIScreen.main.bounds.width - horizontalPadding - cardSpacing
        let targetWidth = floor(availableWidth / 2)
        return min(targetWidth, 250) // keep width similar to design reference
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: cardWidth, maximum: cardWidth), spacing: cardSpacing)
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
                        .fontWeight(.medium)
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
                        .fontWeight(.semibold)
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
            HStack(spacing: 12) {
                // Cart icon with badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("\(itemsCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(5)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Корзина")
                        .fontWeight(.semibold)
                    Text("\(itemsCount) товаров")
                        .font(.caption)
                        .opacity(0.9)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(Int(total)) ₽")
                        .fontWeight(.bold)
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
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
                HStack(spacing: 8) {
                    ForEach(categories) { cat in
                        let cid = cat.id
                        let isSelected = cid == selected || (selected == nil && cat.id == categories.first?.id)
                        Button {
                            onSelect(cid)
                        } label: {
                            Text(cat.name ?? "")
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .padding(.horizontal, 16)
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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.12)
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.gray.opacity(0.12)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                    @unknown default:
                        Color.gray.opacity(0.12)
                    }
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
    let product: ProductDTO
    var onAdd: () -> Void
    
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
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(productId: product.id ?? 0)) {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.08))
                        if let url = productImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                        .clipped()
                                case .failure:
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    }
                                @unknown default:
                                    Color.gray.opacity(0.1)
                                }
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
                
                Text(product.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                PricePill(price: product.base_price ?? 0)
            }
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
}

private struct PricePill: View {
    let price: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Text("от \(Int(price)) ₽")
                .font(.subheadline)
                .fontWeight(.semibold)
            Image(systemName: "chevron.right")
                .font(.subheadline)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}
