import SwiftUI

struct FAQ: Codable, Identifiable {
    let id: Int
    let question: String
    let answer: String
    let sort_order: Int
    let is_active: Bool
}

struct FAQView: View {
    @State private var faqs: [FAQ] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Повторить") {
                        Task { await loadFAQs() }
                    }
                }
                .padding()
            } else if faqs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Пока нет вопросов")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(faqs) { faq in
                        DisclosureGroup {
                            Text(faq.answer)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } label: {
                            Text(faq.question)
                                .font(.headline)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Частые вопросы")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFAQs()
        }
    }
    
    private func loadFAQs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            faqs = try await APIClient.shared.request(["catalog", "faqs"])
            isLoading = false
        } catch {
            errorMessage = "Не удалось загрузить вопросы"
            isLoading = false
        }
    }
}

