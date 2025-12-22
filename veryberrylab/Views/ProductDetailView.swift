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
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(height: 240)
                        .clipped()
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

