import SwiftUI

struct ProductDetailView: View {
    let productId: Int
    @EnvironmentObject var cartVM: CartViewModel
    @StateObject private var vm = ProductDetailViewModel()
    
    var body: some View {
        ScrollView {
            if let product = vm.product {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlString = product.media?.first, let url = URL(string: urlString) {
                        GeometryReader { geometry in
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
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(14)
                    }
                    if let name = product.name {
                        Text(name).font(.title2).bold()
                    }
                    if let desc = product.description {
                        Text(desc).font(.body)
                    }
                    Text("от \(Int(product.base_price ?? 0)) ₽").font(.headline)
                    
                    ForEach(product.modification_groups ?? []) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.name ?? "").font(.headline)
                            Text("Минимум: \(group.min_count ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(group.options ?? []) { opt in
                                Button {
                                    vm.toggleOption(group: group, option: opt)
                                } label: {
                                    HStack {
                                        Text(opt.name ?? "")
                                        Spacer()
                                        Text("+\(Int(opt.extra_price ?? 0)) ₽")
                                        let gid = group.id ?? 0
                                        let oid = opt.id ?? 0
                                        if (group.type ?? "single") == "single" {
                                            Image(systemName: vm.selectedSingle[gid] == oid ? "largecircle.fill.circle" : "circle")
                                        } else {
                                            Image(systemName: vm.selectedOptions.contains(oid) ? "checkmark.square" : "square")
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        let opts = vm.selectionForCart()
                        if let product = vm.product {
                            cartVM.add(product: product, options: opts)
                        }
                    }) {
                        Text("\(Int(vm.computedPrice)) ₽  +")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Товар")
        .overlay { if vm.loading { ProgressView() } }
        .alert(isPresented: Binding(get: { vm.error != nil }, set: { _ in vm.error = nil })) {
            Alert(title: Text("Ошибка"), message: Text(vm.error ?? ""), dismissButton: .default(Text("OK")))
        }
        .task { await vm.load(productId: productId) }
    }
}

