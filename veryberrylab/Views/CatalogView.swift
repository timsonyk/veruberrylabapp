import SwiftUI
import UIKit

struct CatalogView: View {
    @EnvironmentObject var catalogVM: CatalogViewModel
    @EnvironmentObject var cartVM: CartViewModel
    @EnvironmentObject var appState: AppState
    @State private var showCart = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannersSection(banners: catalogVM.banners)
                    CategoriesSection(
                        categories: catalogVM.categories,
                        selected: catalogVM.selectedCategory,
                        onSelect: { id in Task { await catalogVM.selectCategory(id: id) } }
                    )
                    
                    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(catalogVM.products) { product in
                            ProductCard(product: product) {
                                cartVM.add(product: product, options: [])
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Каталог").font(.title3).bold()
                }
            }
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
        }
    }
}

private struct BannersSection: View {
    let banners: [BannerDTO]
    var body: some View {
        if !banners.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(banners) { banner in
                        BannerCard(banner: banner)
                            .frame(width: 260, height: 120)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct CategoriesSection: View {
    let categories: [CategoryDTO]
    let selected: Int?
    var onSelect: (Int?) -> Void
    
    var body: some View {
        if !categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories) { cat in
                        let cid = cat.id
                        Button {
                            onSelect(cid)
                        } label: {
                            Text(cat.name ?? "")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(cid == selected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct BannerCard: View {
    let banner: BannerDTO
    var body: some View {
        ZStack(alignment: .leading) {
            Color.red.opacity(0.1)
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title ?? "").font(.headline)
                if let subtitle = banner.subtitle { Text(subtitle).font(.subheadline) }
            }
            .padding()
        }
        .cornerRadius(14)
    }
}

private struct ProductCard: View {
    let product: ProductDTO
    var onAdd: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.08))
                    if let urlString = product.media?.first, let url = URL(string: urlString) {
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
                .font(.headline)
                .lineLimit(2)
            if let desc = product.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("от \(Int(product.base_price ?? 0)) ₽")
                            .font(.subheadline)
                            .bold()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            NavigationLink(destination: ProductDetailView(productId: product.id ?? 0)) {
                EmptyView()
            }.opacity(0)
        )
    }
}

