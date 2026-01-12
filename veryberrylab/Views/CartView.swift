import SwiftUI
@preconcurrency import WebKit

struct CartView: View {
    @EnvironmentObject var cartVM: CartViewModel
    @EnvironmentObject var appState: AppState

    @State private var showAddressSelection = false
    @State private var showTimeSelection = false
    @State private var showPromoCode = false
    @State private var showCommentSheet = false
    @State private var showPaymentWebView = false
    @State private var paymentURL: URL?
    @State private var isProcessingCheckout = false
    @State private var checkoutError: String?
    @State private var showCheckoutError = false

    private let orderService = OrderService()
    
    // Computed delivery fee from AppState (based on selected address polygon)
    private var currentDeliveryFee: Double {
        cartVM.items.isEmpty ? 0 : appState.deliveryFee
    }
    
    // Computed total with dynamic delivery fee
    private var currentTotal: Double {
        max(0, cartVM.subtotal - cartVM.promoDiscount + currentDeliveryFee)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                if cartVM.items.isEmpty {
                            emptyCartView
                } else {
                            // Delivery Type Picker
                            deliveryTypePicker
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            // Address Section
                            addressSection
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            
                            // Time Section
                            timeSection
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            // Cart Items
                            cartItemsSection
                                .padding(.top, 16)
                            
                            // Recommendations
                            recommendationsSection
                                .padding(.top, 16)
                            
                            // Comment Section
                            commentSection
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            // Do Not Call Toggle
                            doNotCallSection
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                            
                            // Promo Code Section
                            promoCodeSection
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            // Summary Section
                            summarySection
                            .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            Spacer()
                                .frame(height: 120)
                        }
                    }
                }
                
                // Checkout Button
                if !cartVM.items.isEmpty {
                    checkoutButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Корзина")
                        .font(.title3)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !cartVM.items.isEmpty {
                        Button("Очистить") {
                            cartVM.clearCart()
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
        }
    }
}
        }
        .sheet(isPresented: $showAddressSelection) {
            AddressSelectionView()
        }
        .sheet(isPresented: $showTimeSelection) {
            DeliveryTimeSheet()
        }
        .sheet(isPresented: $showPromoCode) {
            PromoCodeSheet()
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentSheet()
        }
    }
    
    // MARK: - Empty Cart
    
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bag")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            Text("Корзина пуста")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Добавьте товары из каталога")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    // MARK: - Delivery Type Picker
    
    private var deliveryTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(DeliveryType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.deliveryType = type
                    }
                } label: {
                    Text(type.title)
                        .font(.subheadline)
                        .foregroundColor(appState.deliveryType == type ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            appState.deliveryType == type
                                ? Color.white
                                : Color.clear
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Address Section
    
    private var addressSection: some View {
        Button {
            showAddressSelection = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: appState.deliveryType == .delivery ? "truck.box" : "building.2")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text(appState.currentDeliveryAddress)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        Button {
            showTimeSelection = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.selectedTimeSlot.displayText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("Изменить время доставки")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Cart Items Section
    
    private var cartItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(cartVM.itemsCount) \(itemsText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ForEach(cartVM.items) { item in
                CartItemRowView(item: item)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var itemsText: String {
        let count = cartVM.itemsCount
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "позиций"
        } else if lastDigit == 1 {
            return "позиция"
        } else if lastDigit >= 2 && lastDigit <= 4 {
            return "позиции"
        } else {
            return "позиций"
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Добавить ещё")
                .font(.headline)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        RecommendationCardView()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        Button {
            showCommentSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text(cartVM.orderComment.isEmpty ? "Комментарий к заказу" : cartVM.orderComment)
                    .font(.subheadline)
                    .foregroundColor(cartVM.orderComment.isEmpty ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Do Not Call Section
    
    private var doNotCallSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text("Не перезванивать")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $cartVM.doNotCall)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    // MARK: - Promo Code Section
    
    private var promoCodeSection: some View {
        Button {
            showPromoCode = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                if let promo = cartVM.appliedPromo {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Промокод \(promo.code)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("-\(Int(cartVM.promoDiscount)) ₽")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Добавить промокод")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Сумма корзины")
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(cartVM.subtotal)) ₽")
            }
            .font(.subheadline)

            if cartVM.promoDiscount > 0 {
                HStack {
                    Text("Скидка")
                        .foregroundColor(.green)
                    Spacer()
                    Text("-\(Int(cartVM.promoDiscount)) ₽")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }

            HStack {
                Text("Доставка")
                    .foregroundColor(.primary)
                Spacer()
                if appState.isCheckingDelivery {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text("\(Int(currentDeliveryFee)) ₽")
                }
            }
            .font(.subheadline)

            if appState.isLoggedIn {
                HStack {
                    Text("Вернётся баллами")
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("+\(cartVM.earnedBonuses)")
                            .font(.subheadline)
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                }
                .font(.subheadline)
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Checkout Button
    
    private var checkoutButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("К оплате")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(currentTotal)) ₽")
                        .font(.title3)
                }
                
                Spacer()

                Button {
                    Task {
                        await processCheckout()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isProcessingCheckout {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isProcessingCheckout ? "Оформление..." : "Оформить заказ")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(14)
                }
                .disabled(isProcessingCheckout)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showPaymentWebView) {
            if let url = paymentURL {
                PaymentWebView(url: url) {
                    // Payment completed
                    showPaymentWebView = false
                    cartVM.clearCart()
                    // TODO: Show success screen
                }
            }
        }
        .alert("Ошибка оформления", isPresented: $showCheckoutError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(checkoutError ?? "Не удалось оформить заказ")
        }
    }

    // MARK: - Checkout Logic

    private func processCheckout() async {
        isProcessingCheckout = true
        defer { isProcessingCheckout = false }

        do {
            // Prepare order items
            let items = cartVM.items.map { item in
                // Convert selected options to JSON string
                let modificationsJSON: String? = {
                    guard !item.selectedOptions.isEmpty else { return nil }
                    let mods = item.selectedOptions.map { ["id": $0.id, "name": $0.name] }
                    guard let data = try? JSONSerialization.data(withJSONObject: mods),
                          let json = String(data: data, encoding: .utf8) else { return nil }
                    return json
                }()

                return OrderItemRequest(
                    product_id: item.productId,
                    quantity: item.quantity,
                    size_id: nil,
                    modifications_json: modificationsJSON
                )
            }

            // Prepare order request
            let request = CreateOrderRequest(
                items: items,
                delivery_type: appState.deliveryType.rawValue,
                address_text: appState.deliveryType == .delivery ? appState.selectedAddress?.fullAddress : nil,
                lat: appState.deliveryType == .delivery ? appState.selectedAddress?.latitude : appState.selectedPickupPoint?.latitude,
                lng: appState.deliveryType == .delivery ? appState.selectedAddress?.longitude : appState.selectedPickupPoint?.longitude,
                city: appState.selectedCity,
                pickup_location_id: appState.deliveryType == .pickup ? appState.selectedPickupPoint?.id : nil,
                comment: cartVM.orderComment.isEmpty ? nil : cartVM.orderComment,
                no_call: cartVM.doNotCall,
                promo_code: cartVM.promoCode.isEmpty ? nil : cartVM.promoCode
            )

            // Create order
            let _ = try await orderService.createOrder(request)

            // TODO: Add VTB Business payment integration
            await MainActor.run {
                cartVM.clearCart()
                // TODO: Show success screen / payment screen
            }

        } catch {
            await MainActor.run {
                checkoutError = "Ошибка при оформлении заказа: \(error.localizedDescription)"
                showCheckoutError = true
            }
        }
    }
}

// MARK: - Cart Item Row View

private struct CartItemRowView: View {
    @EnvironmentObject var cartVM: CartViewModel
    let item: CartItem
    
    private var imageURL: URL? {
        guard let urlString = item.media?.first,
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
        HStack(alignment: .top, spacing: 12) {
            // Product Image
            ZStack {
            Rectangle()
                    .fill(Color.gray.opacity(0.1))
                
                if let url = imageURL {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                        Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                }
            .frame(width: 64, height: 64)
                .clipped()
            .cornerRadius(10)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(2)

                if !item.selectedOptions.isEmpty {
                    Text(item.selectedOptions.map { $0.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(Int(item.totalPrice)) ₽")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Quantity Controls
            HStack(spacing: 0) {
                Button {
                    cartVM.decrement(item)
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Text("\(item.quantity)")
                    .font(.subheadline)
                    .frame(width: 32)
                
                Button {
                    cartVM.increment(item)
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Recommendation Card View

private struct RecommendationCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 140, height: 120)
                .cornerRadius(12)
            
            Text("Very Berry M")
                .font(.caption)
                .lineLimit(2)

            Text("от 5090 ₽")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 140)
        .padding(8)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


// MARK: - Payment WebView


struct PaymentWebView: View {
    let url: URL
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            WebView(url: url, onComplete: onComplete)
                .navigationTitle("Оплата")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отменить") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let onComplete: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onComplete: () -> Void

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if payment is complete by looking at URL
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString

                // Payment success redirect
                if urlString.contains("success") || urlString.contains("completed") {
                    DispatchQueue.main.async {
                        self.onComplete()
                    }
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
    }
}
