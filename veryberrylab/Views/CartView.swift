import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartVM: CartViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if cartVM.items.isEmpty {
                    Spacer()
                    Text("Корзина пуста").foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(cartVM.items) { item in
                                CartItemRow(item: item)
                                    .environmentObject(cartVM)
                            }
                            
                            RecommendationSection()
                            SummarySection(subtotal: cartVM.subtotal, delivery: cartVM.deliveryFee, total: cartVM.total)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    
                    Button(action: {
                        // TODO: order creation call
                    }) {
                        Text("Оформить заказ — \(Int(cartVM.total)) ₽")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(14)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Корзина").font(.title3).bold()
                }
            }
        }
    }
}

private struct CartItemRow: View {
    @EnvironmentObject var cartVM: CartViewModel
    let item: CartItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay {
                    if let urlString = item.media?.first, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            VStack {
                                Image(systemName: "photo")
                                Text("Failed").font(.caption)
                            }
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                        Text("No image").font(.caption)
                    }
                }
                }
                .clipped()
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                if !item.selectedOptions.isEmpty {
                    Text(item.selectedOptions.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("\(Int(item.totalPrice)) ₽").font(.subheadline).bold()
            }
            Spacer()
            HStack {
                Button { cartVM.decrement(item) } label: {
                    Image(systemName: "minus.circle")
                }
                Text("\(item.quantity)")
                    .frame(width: 28)
                Button { cartVM.increment(item) } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

private struct RecommendationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Добавить ещё").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        VStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 100)
                                .cornerRadius(12)
                            Text("Товар").font(.subheadline)
                            Text("3990 ₽").font(.subheadline).bold()
                        }
                        .frame(width: 120)
                    }
                }
            }
        }
    }
}

private struct SummarySection: View {
    let subtotal: Double
    let delivery: Double
    let total: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Сумма корзины"); Spacer(); Text("\(Int(subtotal)) ₽") }
            HStack { Text("Доставка"); Spacer(); Text("\(Int(delivery)) ₽") }
            HStack { Text("К оплате").bold(); Spacer(); Text("\(Int(total)) ₽").bold() }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

