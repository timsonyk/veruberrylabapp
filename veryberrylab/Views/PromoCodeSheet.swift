import SwiftUI

struct PromoCodeSheet: View {
    @EnvironmentObject var cartVM: CartViewModel
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Promo Code Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Введите промокод")
                        .font(.headline)
                    
                    HStack {
                        TextField("Промокод", text: $cartVM.promoCode)
                            .textFieldStyle(.plain)
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                        
                        if !cartVM.promoCode.isEmpty {
                            Button {
                                cartVM.promoCode = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    
                    if let error = cartVM.promoError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Applied Promo
                if let promo = cartVM.appliedPromo {
                    appliedPromoView(promo)
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Apply Button
                applyButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Промокод")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Applied Promo View
    
    private func appliedPromoView(_ promo: PromoCode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Промокод применён")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(promo.code)
                        .font(.headline)

                    Text(promoDescription(promo))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("-\(Int(cartVM.promoDiscount)) ₽")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(Color.green.opacity(0.1))
            .cornerRadius(14)
            
            Button {
                cartVM.removePromoCode()
            } label: {
                Text("Удалить промокод")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func promoDescription(_ promo: PromoCode) -> String {
        switch promo.discountType {
        case .percentage:
            return "Скидка \(Int(promo.discountValue))%"
        case .fixed:
            return "Скидка \(Int(promo.discountValue)) ₽"
        }
    }
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        Button {
            Task {
                await cartVM.applyPromoCode()
                if cartVM.appliedPromo != nil {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if cartVM.isApplyingPromo {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Применить")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(cartVM.promoCode.isEmpty ? Color.gray : Color.red)
            .cornerRadius(14)
        }
        .disabled(cartVM.promoCode.isEmpty || cartVM.isApplyingPromo)
    }
}
