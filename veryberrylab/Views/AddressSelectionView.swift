import SwiftUI
import MapKit
import CoreLocation
#if canImport(YandexMapsMobile)
import YandexMapsMobile
#endif

struct AddressSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var locationManager = LocationManager()
    @State private var showAddNewAddress = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7330, longitude: 37.5847),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isMapMoving = false
    @State private var addressToDelete: DeliveryAddress?
    @State private var showDeleteConfirmation = false
    @State private var shouldFollowUserLocation = false
    @State private var isProgrammaticMove = false
    @State private var deliveryZones: [DeliveryZoneDTO] = []
    @State private var mapRefreshID = UUID() // Для принудительного обновления карты
    @State private var showCityPicker = false
    @State private var debounceTimer: Timer? // Для debounce геокодирования
    
    // Pickup points (магазины самовывоза)
    private let pickupPoints: [String: [PickupPoint]] = [
        "Москва": [
            PickupPoint(id: 1, name: "Very Berry Lab Москва", address: "Москва, ул. Тверская, 1", latitude: 55.7558, longitude: 37.6173, workingHours: "Пн-Вс 10:00-22:00")
        ],
        "Санкт-Петербург": [
            PickupPoint(id: 2, name: "Very Berry Lab СПб", address: "Санкт-Петербург, Невский проспект, 1", latitude: 59.9343, longitude: 30.3351, workingHours: "Пн-Вс 10:00-22:00")
        ]
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map (Yandex if available, otherwise Apple Maps)
            CenterTrackingMapView(
                region: $mapRegion,
                isMoving: $isMapMoving,
                onRegionChanged: { region in
                    // Разрешаем карте свободно двигаться
                    // isProgrammaticMove больше не блокирует обновления
                }
            )
            .id(mapRefreshID) // Обновляем карту при изменении ID
            .ignoresSafeArea(edges: .top)
                
                // Bottom navigation buttons
                bottomNavigationButtons
                
                // Address List Sheet
                addressListSheet
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showAddNewAddress) {
            AddNewAddressMapView(onAddressAdded: {
                showAddNewAddress = false
                // НЕ двигаем камеру после сохранения
            })
        }
        .sheet(isPresented: $showCityPicker) {
            cityPickerSheet
        }
        .alert("Удалить адрес?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {
                addressToDelete = nil
            }
            Button("Удалить", role: .destructive) {
                if let address = addressToDelete {
                    withAnimation {
                        appState.removeAddress(address)
                    }
                }
                addressToDelete = nil
            }
        } message: {
            if let address = addressToDelete {
                Text(address.fullAddress)
            }
        }
        .onAppear {
            updateMapRegion()
            loadDeliveryZones()
        }
        .onChange(of: locationManager.lastLocation) { location in
            guard let loc = location else {
                print("⚠️ Location is nil")
                return
            }
            
            guard shouldFollowUserLocation else {
                print("⚠️ shouldFollowUserLocation is false, ignoring location update")
                return
            }
            
            print("🎯 Moving map to user location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
            
            // Programmatic move к user location
            isProgrammaticMove = true
            mapRegion = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )
            shouldFollowUserLocation = false
        }
    }
    
    // MARK: - Map Annotations
    
    private var mapAnnotations: [MapAnnotationItem] {
        if let address = appState.selectedAddress,
           let lat = address.latitude,
           let lon = address.longitude {
            return [MapAnnotationItem(
                id: address.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )]
        }
        return []
    }
    
    // MARK: - Bottom Navigation
    
    private var bottomNavigationButtons: some View {
        HStack {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Spacer()
            
            // City Picker Button
            Button {
                showCityPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(appState.selectedCity)
                        .font(.body)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 450)
    }
    
    // MARK: - Address List Sheet
    
    private var addressListSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Delivery Type Picker (Доставка / Самовывоз)
            Picker("", selection: $appState.deliveryType) {
                ForEach(DeliveryType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .onChange(of: appState.deliveryType) { newType in
                handleDeliveryTypeChange(newType)
            }
            
            // Title
            HStack {
                Text(appState.deliveryType == .delivery ? "Мои адреса" : "Пункты самовывоза")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.top, 12)
            
            // Content based on delivery type
            if appState.deliveryType == .delivery {
                deliveryAddressListContent
            } else {
                pickupPointsListContent
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Delivery Address List Content
    
    private var deliveryAddressListContent: some View {
        VStack(spacing: 0) {
            // Address List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(appState.savedAddresses) { address in
                        AddressRowWithDelete(
                            address: address,
                            isSelected: appState.selectedAddress?.id == address.id,
                            onSelect: {
                                appState.selectAddress(address)
                                moveMapToAddress(address)
                            },
                            onDelete: {
                                addressToDelete = address
                                showDeleteConfirmation = true
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            // Add New Address Button
            Button {
                showAddNewAddress = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.title3)
                    Text("Добавить новый адрес")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Pickup Points List Content
    
    private var pickupPointsListContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    if let points = pickupPoints[appState.selectedCity] {
                        ForEach(points) { point in
                            PickupPointRow(
                                point: point,
                                isSelected: appState.selectedPickupPoint?.id == point.id,
                                onSelect: {
                                    appState.selectedPickupPoint = point
                                    moveMapToPickupPoint(point)
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                    } else {
                        Text("Нет доступных пунктов самовывоза в выбранном городе")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - City Picker Sheet
    
    private var cityPickerSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            // Title
            Text("Выберите город")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            // Cities
            VStack(spacing: 0) {
                ForEach(["Москва", "Санкт-Петербург"], id: \.self) { city in
                    Button {
                        selectCity(city)
                        showCityPicker = false
                    } label: {
                        HStack {
                            Text(city)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            if appState.selectedCity == city {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    if city != "Санкт-Петербург" {
                        Divider()
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .presentationDetents([.height(280)])
    }
    
    // MARK: - Helpers
    
    private func moveMapToAddress(_ address: DeliveryAddress) {
        guard let lat = address.latitude,
              let lon = address.longitude else { return }
        
        print("🎯 Moving map to address: \(lat), \(lon)")
        
        isProgrammaticMove = true
        
        // Обновляем регион И ID карты для принудительного обновления
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        )
        mapRefreshID = UUID()
    }
    
    private func updateMapRegion() {
        guard let address = appState.selectedAddress else { return }
        moveMapToAddress(address)
    }
    
    private func loadDeliveryZones() {
        Task {
            do {
                deliveryZones = try await appState.catalogService.fetchDeliveryZones()
            } catch {
                // Игнорируем ошибку загрузки зон
            }
        }
    }
    
    private func handleDeliveryTypeChange(_ newType: DeliveryType) {
        if newType == .pickup {
            // При переключении на самовывоз, показываем первый доступный магазин
            if let points = pickupPoints[appState.selectedCity], let firstPoint = points.first {
                appState.selectedPickupPoint = firstPoint
                moveMapToPickupPoint(firstPoint)
            }
        }
    }
    
    private func moveMapToPickupPoint(_ point: PickupPoint) {
        print("🎯 Moving map to pickup point: \(point.latitude), \(point.longitude)")
        
        isProgrammaticMove = true
        
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        )
        mapRefreshID = UUID()
    }
    
    private func selectCity(_ city: String) {
        appState.selectedCity = city
        
        // Определяем координаты города
        let cityCoordinates: [String: CLLocationCoordinate2D] = [
            "Москва": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
            "Санкт-Петербург": CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351)
        ]
        
        guard let coordinate = cityCoordinates[city] else { return }
        
        isProgrammaticMove = true
        
        // Увеличиваем начальный zoom для лучшей прогрузки карты
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        mapRefreshID = UUID()
        
        // Если режим самовывоза, выбираем первый магазин в городе
        if appState.deliveryType == .pickup,
           let points = pickupPoints[city],
           let firstPoint = points.first {
            appState.selectedPickupPoint = firstPoint
            // Небольшая задержка для прогрузки карты перед zoom in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.moveMapToPickupPoint(firstPoint)
            }
        }
    }
}

// MARK: - Pickup Point Row

struct PickupPointRow: View {
    let point: PickupPoint
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(point.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(point.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let hours = point.workingHours {
                        Text(hours)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Delivery Time Marker

private struct DeliveryTimeMarker: View {
    let minutes: Int
    
    private var hoursText: String {
        let hours = minutes / 60
        return "\(hours) часа"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(hoursText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .cornerRadius(8)
            
            // Triangle pointer
            Triangle()
                .fill(Color.red)
                .frame(width: 12, height: 8)
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Address Row With Delete

private struct AddressRowWithDelete: View {
    let address: DeliveryAddress
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Select Button
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    // Checkmark
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Address Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(address.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let details = address.detailsText {
                            Text(details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Add New Address Map View

struct AddNewAddressMapView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var onAddressAdded: (() -> Void)?

    @StateObject private var locationManager = LocationManager()
    @State private var mapRegion: MKCoordinateRegion
    @State private var isMapMoving = false
    @State private var detectedAddress: String = "Определяем адрес..."
    @State private var showAddressForm = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isProgrammaticMove = false
    @State private var shouldFollowUserLocation = false
    @State private var mapRefreshID = UUID() // Для принудительного обновления карты

    // Delivery zone check
    @State private var isCheckingDelivery = false
    @State private var deliveryAvailable = false
    @State private var deliveryTime: Int?
    
    // Debounce timer для геокодирования
    @State private var geocodeTimer: Timer?
    
    init(onAddressAdded: (() -> Void)? = nil) {
        self.onAddressAdded = onAddressAdded
        // Инициализируем mapRegion в зависимости от выбранного города через @AppStorage или дефолтное значение
        // Временно используем дефолтную Москву, обновим в onAppear
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ZStack {
            // Map
            CenterTrackingMapView(
                region: $mapRegion,
                isMoving: $isMapMoving,
                onRegionChanged: { region in
                    // Разрешаем карте свободно двигаться
                    if !isProgrammaticMove {
                        // Отменяем предыдущий таймер
                        geocodeTimer?.invalidate()
                        
                        // Запускаем новый таймер (debounce)
                        geocodeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            geocodeLocation(region.center)
                            checkDeliveryZone(coordinate: region.center)
                        }
                    }
                    // Сбрасываем флаг сразу после первого callback
                    isProgrammaticMove = false
                }
            )
            .id(mapRefreshID) // Обновляем карту при изменении ID
            .ignoresSafeArea()
            
            // Center Pin (always fixed in center)
            VStack {
                Spacer()
                
                // Pin
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(y: isMapMoving ? -10 : 0)
                        .animation(.spring(response: 0.3), value: isMapMoving)
                    
                    // Shadow dot
                    Ellipse()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: isMapMoving ? 8 : 12, height: isMapMoving ? 4 : 6)
                        .animation(.spring(response: 0.3), value: isMapMoving)
                }
                .offset(y: -20) // Offset to align pin point with center
                
                Spacer()
            }
            
            // Top Bar
            VStack {
                HStack {
                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("Укажите адрес")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Location Button (floating, lower position)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        print("🔵 'Найди меня' button tapped (AddNewAddressMapView)")
                        
                        // Если уже есть локация - принудительно обновляем карту
                        if let location = locationManager.lastLocation {
                            print("🎯 Jumping to location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            
                            isProgrammaticMove = true
                            
                            // Обновляем регион И ID карты с БОЛЬШИМ приближением
                            mapRegion = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                            )
                            mapRefreshID = UUID()
                            geocodeLocation(location.coordinate)
                            checkDeliveryZone(coordinate: location.coordinate)
                        } else {
                            print("🔵 No location yet, requesting permission")
                            shouldFollowUserLocation = true
                            locationManager.requestPermission()
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 52, height: 52)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 280) // Над нижним sheet'ом
            }
            
            // Bottom Sheet
            VStack {
                Spacer()
                
                addressBottomSheet
            }
        }
        .sheet(isPresented: $showAddressForm) {
            AddressDetailsFormView(
                address: detectedAddress,
                coordinate: selectedCoordinate ?? mapRegion.center,
                onSaved: {
                    showAddressForm = false
                    dismiss()
                    onAddressAdded?()
                }
            )
        }
        .onAppear {
            // Устанавливаем карту на выбранный город
            let cityCoordinates: [String: CLLocationCoordinate2D] = [
                "Москва": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
                "Санкт-Петербург": CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351)
            ]
            
            if let coordinate = cityCoordinates[appState.selectedCity] {
                // Устанавливаем хороший начальный zoom для прогрузки карты
                mapRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
            
            geocodeLocation(mapRegion.center)
            checkDeliveryZone(coordinate: mapRegion.center)
        }
        .onChange(of: locationManager.lastLocation) { location in
            guard shouldFollowUserLocation, let loc = location else {
                return
            }
            
            print("🎯 Jumping to user location (AddNewAddressMapView): \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
            
            isProgrammaticMove = true
            shouldFollowUserLocation = false
            
            // Обновляем регион И ID карты с БОЛЬШИМ приближением
            mapRegion = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )
            mapRefreshID = UUID()
            geocodeLocation(loc.coordinate)
            checkDeliveryZone(coordinate: loc.coordinate)
        }
    }
    
    // MARK: - Address Bottom Sheet
    
    private var addressBottomSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                // Detected Address
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detectedAddress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        // Delivery status
                        if isCheckingDelivery {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Проверяем зону...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if !deliveryAvailable {
                            Text("Доставка недоступна")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if let time = deliveryTime {
                            Text("Доставка ~ \(time) мин")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if isMapMoving {
                            Text("Отпустите для выбора")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Confirm Button
                Button {
                    selectedCoordinate = mapRegion.center
                    showAddressForm = true
                } label: {
                    Text(deliveryAvailable ? "Подтвердить адрес" : "Доставка недоступна")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(deliveryAvailable && detectedAddress != "Определяем адрес..." ? Color.red : Color.gray)
                        .cornerRadius(14)
                }
                .disabled(!deliveryAvailable || detectedAddress == "Определяем адрес...")
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Helpers
    // MARK: - Geocoding (Yandex Geocoder HTTP API)
    
    private func geocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        // Получаем API ключ для Yandex Geocoder
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "YandexGeocoderApiKey") as? String, !apiKey.isEmpty else {
            print("❌ YandexGeocoderApiKey not found")
            DispatchQueue.main.async {
                self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
            }
            return
        }
        
        let urlString = "https://geocode-maps.yandex.ru/1.x/?apikey=\(apiKey)&geocode=\(coordinate.longitude),\(coordinate.latitude)&format=json&kind=house&results=1&lang=ru_RU"
        
        print("🔍 Yandex Geocoding: \(coordinate.latitude), \(coordinate.longitude)")
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Geocoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                }
                return
            }
            
            // Проверяем на ошибку API ключа
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["message"] as? String {
                print("⚠️ API Response: \(errorMessage)")
                if errorMessage.contains("Invalid api key") {
                    print("❌ INVALID API KEY! Нужен ключ для HTTP Geocoder, не MapKit!")
                }
                DispatchQueue.main.async {
                    self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                }
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let responseObj = json["response"] as? [String: Any],
                      let geoObjectCollection = responseObj["GeoObjectCollection"] as? [String: Any],
                      let featureMember = geoObjectCollection["featureMember"] as? [[String: Any]],
                      !featureMember.isEmpty,
                      let firstFeature = featureMember.first,
                      let geoObject = firstFeature["GeoObject"] as? [String: Any] else {
                    print("⚠️ Empty or invalid response structure")
                    DispatchQueue.main.async {
                        self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                    }
                    return
                }
                
                // Извлекаем адрес
                if let metaDataProperty = geoObject["metaDataProperty"] as? [String: Any],
                   let geocoderMetaData = metaDataProperty["GeocoderMetaData"] as? [String: Any],
                   let addressText = geocoderMetaData["text"] as? String, !addressText.isEmpty {
                    print("✅ Yandex Address: \(addressText)")
                    DispatchQueue.main.async {
                        self.detectedAddress = addressText
                    }
                    return
                }
                
                // Fallback: coordinates
                DispatchQueue.main.async {
                    self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                }
            } catch {
                print("❌ Parse error: \(error)")
                DispatchQueue.main.async {
                    self.detectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                }
            }
        }.resume()
    }
    
    // MARK: - Delivery Zone Check
    
    private func checkDeliveryZone(coordinate: CLLocationCoordinate2D) {
        isCheckingDelivery = true
        deliveryAvailable = false // По умолчанию недоступна
        deliveryTime = nil
        
        Task {
            do {
                let response = try await appState.catalogService.checkDelivery(
                    lat: coordinate.latitude,
                    lng: coordinate.longitude,
                    city: "Москва"
                )
                
                await MainActor.run {
                    // Только координаты определяют доступность
                    deliveryAvailable = response.available
                    deliveryTime = response.available ? response.sla_minutes : nil
                    isCheckingDelivery = false
                }
            } catch {
                await MainActor.run {
                    deliveryAvailable = false
                    deliveryTime = nil
                    isCheckingDelivery = false
                }
            }
        }
    }
}

// MARK: - Center Tracking Map (Yandex if available, else Apple Maps)

struct CenterTrackingMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var isMoving: Bool
    var onRegionChanged: (MKCoordinateRegion) -> Void
    
    var body: some View {
#if canImport(YandexMapsMobile)
        YandexMapWithCenterTracking(region: $region, isMoving: $isMoving, onRegionChanged: onRegionChanged)
#else
        MapViewWithCenterTracking(region: $region, isMoving: $isMoving, onRegionChanged: onRegionChanged)
#endif
    }
}

// MARK: - Apple Maps

struct MapViewWithCenterTracking: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var isMoving: Bool
    var onRegionChanged: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // ✅ FIXED: Только программные изменения (кнопка "Найти меня", выбор города)
        // НЕ синхронизируем во время или после user gesture
        guard !context.coordinator.isUserInteraction else { return }

        let currentCenter = mapView.region.center
        let newCenter = region.center
        let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
            .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))

        // Обновляем карту ТОЛЬКО при смене координат (больше 10м)
        // Zoom пользователь может менять свободно
        if distance > 10 {
            context.coordinator.isProgrammaticChange = true
            
            // Применяем новый center, но сохраняем текущий zoom пользователя
            var newRegion = region
            newRegion.span = mapView.region.span // Сохраняем zoom пользователя
            
            mapView.setRegion(newRegion, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithCenterTracking
        private var debounceTimer: Timer?
        
        // ✅ Флаг: различаем user gesture vs программное изменение
        var isProgrammaticChange = false
        var isUserInteraction = false
        
        init(_ parent: MapViewWithCenterTracking) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Если НЕ программное изменение → это user gesture
            if !isProgrammaticChange {
                isUserInteraction = true
            }
            
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
            debounceTimer?.invalidate()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isProgrammaticChange = false // Сбрасываем флаг
            
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.parent.isMoving = false
                    // ✅ Обновляем SwiftUI state ТОЛЬКО после user gesture
                    self.parent.region = mapView.region
                    self.parent.onRegionChanged(mapView.region)
                    
                    // Разрешаем следующие user interactions
                    self.isUserInteraction = false
                }
            }
        }
    }
}

#if canImport(YandexMapsMobile)
// MARK: - Yandex Maps

struct YandexMapWithCenterTracking: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var isMoving: Bool
    var onRegionChanged: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> YMKMapView {
        let mapView: YMKMapView = YMKMapView(frame: .zero)
        
        // Конвертируем latitudeDelta в zoom level
        // zoom ≈ log2(360 / latitudeDelta)
        let zoom = Float(log2(360.0 / region.span.latitudeDelta))
        
        let camera = YMKCameraPosition(
            target: YMKPoint(latitude: region.center.latitude, longitude: region.center.longitude),
            zoom: zoom,
            azimuth: 0,
            tilt: 0
        )
        let anim = YMKAnimation(type: .smooth, duration: 0)

        guard let mapWindow = mapView.mapWindow else { return mapView }
        let map = mapWindow.map
        map.move(with: camera, animation: anim, cameraCallback: nil)
        map.addCameraListener(with: context.coordinator)
        return mapView
    }
    
    func updateUIView(_ mapView: YMKMapView, context: Context) {
        // ✅ FIXED: Только программные изменения (кнопка "Найти меня", выбор города)
        guard !context.coordinator.isUserInteraction else { return }

        guard let mapWindow = mapView.mapWindow else { return }
        let map = mapWindow.map
        let current = map.cameraPosition.target
        let distance = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))

        // Обновляем ТОЛЬКО при смене координат (больше 10м)
        // Zoom пользователь может менять свободно
        if distance > 10 {
            context.coordinator.isProgrammaticChange = true
            
            // Перемещаем камеру, но сохраняем текущий zoom пользователя
            let camera = YMKCameraPosition(
                target: YMKPoint(latitude: region.center.latitude, longitude: region.center.longitude),
                zoom: map.cameraPosition.zoom, // Сохраняем zoom пользователя
                azimuth: map.cameraPosition.azimuth,
                tilt: map.cameraPosition.tilt
            )
            let anim = YMKAnimation(type: .linear, duration: 0) // БЕЗ анимации
            map.move(with: camera, animation: anim, cameraCallback: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, YMKMapCameraListener {
        var parent: YandexMapWithCenterTracking
        private var debounceTimer: Timer?
        
        // ✅ Флаги для различения user gesture vs программного изменения
        var isProgrammaticChange = false
        var isUserInteraction = false
        
        init(_ parent: YandexMapWithCenterTracking) {
            self.parent = parent
        }
        
        func onCameraPositionChanged(
            with map: YMKMap,
            cameraPosition: YMKCameraPosition,
            cameraUpdateReason: YMKCameraUpdateReason,
            finished: Bool
        ) {
            // Определяем тип изменения
            if cameraUpdateReason == .gestures {
                isUserInteraction = true
            }
            
            DispatchQueue.main.async {
                self.parent.isMoving = !finished
            }
            
            // Обновляем SwiftUI state только после завершения движения
            guard finished else { return }
            
            isProgrammaticChange = false // Сбрасываем флаг
            
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let newRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude),
                    span: self.parent.region.span
                )
                DispatchQueue.main.async {
                    self.parent.region = newRegion
                    self.parent.onRegionChanged(newRegion)
                    self.parent.isMoving = false
                    self.isUserInteraction = false // Разрешаем следующие interactions
                }
            }
        }
    }
}
#endif

// MARK: - Address Details Form View

struct AddressDetailsFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let address: String
    let coordinate: CLLocationCoordinate2D
    var onSaved: (() -> Void)?
    
    @State private var isPrivateHouse = false
    @State private var entrance: String = ""
    @State private var apartment: String = ""
    @State private var floor: String = ""
    @State private var intercom: String = ""
    @State private var comment: String = ""
    
    private var isValid: Bool {
        if isPrivateHouse {
            return true
        }
        return !entrance.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Address Card
                    addressCard
                    
                    // Private House Toggle
                    privateHouseToggle
                    
                    // Required Fields (if not private house)
                    if !isPrivateHouse {
                        requiredFieldsSection
                    }
                    
                    // Optional Fields
                    optionalFieldsSection
                    
                    // Comment Section
                    commentSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Детали адреса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Назад") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
        }
    }
    
    // MARK: - Address Card
    
    private var addressCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Адрес доставки")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(address)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    // MARK: - Private House Toggle
    
    private var privateHouseToggle: some View {
        Button {
            withAnimation {
                isPrivateHouse.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isPrivateHouse ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isPrivateHouse ? .red : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Частный дом")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("Без подъезда и квартиры")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(isPrivateHouse ? Color.red.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPrivateHouse ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Required Fields
    
    private var requiredFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Обязательные поля")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Entrance (required)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Подъезд")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("*")
                        .foregroundColor(.red)
                }
                
                TextField("Номер подъезда", text: $entrance)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(entrance.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Optional Fields
    
    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isPrivateHouse ? "Дополнительно" : "Необязательные поля")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !isPrivateHouse {
                // Apartment
                VStack(alignment: .leading, spacing: 4) {
                    Text("Квартира / офис")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Номер квартиры или офиса", text: $apartment)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Floor
                VStack(alignment: .leading, spacing: 4) {
                    Text("Этаж")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Номер этажа", text: $floor)
                        .keyboardType(.numberPad)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            
            // Intercom
            VStack(alignment: .leading, spacing: 4) {
                Text("Домофон")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Код домофона", text: $intercom)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Комментарий для курьера")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            TextEditor(text: $comment)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            Text("Например: калитка справа, звонить не нужно")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                saveAddress()
            } label: {
                Text("Сохранить адрес")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValid ? Color.red : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!isValid)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Save
    
    private func saveAddress() {
        let newAddress = DeliveryAddress(
            street: address,
            building: nil,
            apartment: apartment.isEmpty ? nil : apartment,
            entrance: entrance.isEmpty ? nil : entrance,
            floor: floor.isEmpty ? nil : floor,
            intercom: intercom.isEmpty ? nil : intercom,
            comment: comment.isEmpty ? nil : comment,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            isDefault: appState.savedAddresses.isEmpty,
            isPrivateHouse: isPrivateHouse
        )
        
        appState.addAddress(newAddress)
        
        // Call callback to dismiss all sheets and return to address list
        if let onSaved = onSaved {
            onSaved()
        } else {
            dismiss()
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        let status = manager.authorizationStatus
        
        if status == .notDetermined {
            // Первый запрос разрешения
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Разрешение уже есть - сразу запускаем
            manager.startUpdatingLocation()
        } else {
            // Разрешение отклонено
            print("⚠️ Location permission denied")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        lastLocation = location
        // Останавливаем обновления после получения первой точки
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("🔐 Authorization status changed: \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("✅ Location authorized - starting updates")
            manager.startUpdatingLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            print("❌ Location permission denied or restricted")
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let addressAdded = Notification.Name("addressAdded")
}
