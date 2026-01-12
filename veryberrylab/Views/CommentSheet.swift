import SwiftUI

struct CommentSheet: View {
    @EnvironmentObject var cartVM: CartViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var comment: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Comment Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Комментарий к заказу")
                        .font(.headline)
                    
                    TextEditor(text: $comment)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .focused($isTextFieldFocused)
                    
                    Text("Например: позвонить за 10 минут, не звонить в домофон")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Quick Comments
                quickCommentsSection
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // Save Button
                saveButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Комментарий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                comment = cartVM.orderComment
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Quick Comments
    
    private let quickComments = [
        "Позвонить за 10 минут",
        "Не звонить в домофон",
        "Оставить у двери",
        "Позвонить заранее"
    ]
    
    private var quickCommentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Быстрые комментарии")
                .font(.subheadline)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(quickComments, id: \.self) { quickComment in
                    Button {
                        if comment.isEmpty {
                            comment = quickComment
                        } else if !comment.contains(quickComment) {
                            comment += ", " + quickComment.lowercased()
                        }
                    } label: {
                        Text(quickComment)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            cartVM.orderComment = comment
            dismiss()
        } label: {
            Text("Сохранить")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(14)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
