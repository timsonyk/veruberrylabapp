import SwiftUI

struct StoreLocation: Codable, Identifiable {
    let id: Int
    let city: String
    let address_text: String
    let lat: Double?
    let lng: Double?
    let phone: String?
    let working_hours: String?
    let sort_order: Int
    let is_active: Bool
}

struct StoreLocationsView: View {
    @State private var locations: [StoreLocation] = []
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
                        Task { await loadLocations() }
                    }
                }
                .padding()
            } else if locations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Пока нет адресов")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(locations) { location in
                        VStack(alignment: .leading, spacing: 12) {
                            // City
                            Text(location.city)
                                .font(.headline)
                                .foregroundColor(.primary)

                            // Address
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.body)
                                Text(location.address_text)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            // Phone
                            if let phone = location.phone {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "phone.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.body)
                                    Link(phone, destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!)
                                        .font(.body)
                                }
                            }

                            // Working hours
                            if let hours = location.working_hours {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "clock.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.body)
                                    Text(hours)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Open in Yandex Maps button
                            if let lat = location.lat, let lng = location.lng {
                                Button {
                                    openInYandexMaps(lat: lat, lng: lng, city: location.city)
                                } label: {
                                    HStack {
                                        Image(systemName: "map.fill")
                                        Text("Открыть в Яндекс Картах")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Наши адреса")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLocations()
        }
    }
    
    private func loadLocations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            locations = try await APIClient.shared.request(["catalog", "store_locations"])
            isLoading = false
        } catch {
            errorMessage = "Не удалось загрузить адреса"
            isLoading = false
        }
    }
    
    private func openInYandexMaps(lat: Double, lng: Double, city: String) {
        // Use specific links for Moscow and St. Petersburg, fallback to coordinates for others
        let yandexMapsUrl: String
        if city == "Москва" || city.lowercased().contains("москва") {
            yandexMapsUrl = "https://yandex.ru/maps/org/veriberrilab/59793837512?si=xcfxk1j2puhccy1dhec15kf7mr"
        } else if city == "Санкт-Петербург" || city.lowercased().contains("петербург") {
            yandexMapsUrl = "https://yandex.ru/maps/org/veriberrilab/30589146118?si=xcfxk1j2puhccy1dhec15kf7mr"
        } else {
            // Fallback for other cities - use coordinates
            yandexMapsUrl = "https://yandex.ru/maps/?ll=\(lng),\(lat)&z=16"
        }

        if let url = URL(string: yandexMapsUrl) {
            UIApplication.shared.open(url)
        }
    }
}

