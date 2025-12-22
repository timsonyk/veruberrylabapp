import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var product: ProductDTO?
    @Published var loading = false
    @Published var error: String?
    @Published var selectedOptions: Set<Int> = []
    @Published var selectedSingle: [Int: Int] = [:] // groupId -> optionId
    
    private let service = CatalogService()
    
    var computedPrice: Double {
        guard let product else { return 0 }
        let modsSum = (product.modification_groups ?? []).flatMap { group -> [Double] in
            let gid = group.id ?? 0
            return (group.options ?? []).compactMap { opt in
                guard let optId = opt.id, let price = opt.extra_price else { return nil }
                if (group.type ?? "single") == "single" {
                    return selectedSingle[gid] == optId ? price : nil
                } else {
                    return selectedOptions.contains(optId) ? price : nil
                }
            }
        }.reduce(0, +)
        return (product.base_price ?? 0) + modsSum
    }
    
    func load(productId: Int) async {
        loading = true
        do {
            let p = try await service.fetchProduct(id: productId)
            product = p
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
    
    func toggleOption(group: ModificationGroupDTO, option: ModificationOptionDTO) {
        let gid = group.id ?? 0
        let oid = option.id ?? 0
        let isSingle = (group.type ?? "single") == "single"
        if isSingle {
            selectedSingle[gid] = oid
        } else {
            if selectedOptions.contains(oid) {
                selectedOptions.remove(oid)
            } else {
                selectedOptions.insert(oid)
            }
        }
    }
    
    func selectionForCart() -> [SelectedOption] {
        guard let product else { return [] }
        var result: [SelectedOption] = []
        for group in product.modification_groups ?? [] {
            let gid = group.id ?? 0
            let isSingle = (group.type ?? "single") == "single"
            for opt in group.options ?? [] {
                guard let optId = opt.id else { continue }
                if isSingle, selectedSingle[gid] == optId {
                    result.append(.init(id: optId, name: opt.name ?? "", extraPrice: opt.extra_price ?? 0))
                }
                if !isSingle, selectedOptions.contains(optId) {
                    result.append(.init(id: optId, name: opt.name ?? "", extraPrice: opt.extra_price ?? 0))
                }
            }
        }
        return result
    }
}

