import SwiftUI
import MapKit
import CoreLocation
#if canImport(YandexMapsMobile)
import YandexMapsMobile
#endif

struct AddressSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddNewAddress = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7330, longitude: 37.5847),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isMapMoving = false
    @State private var addressToDelete: DeliveryAddress?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map (Yandex if available, otherwise Apple Maps)
                CenterTrackingMapView(
                    region: $mapRegion,
                    isMoving: $isMapMoving,
                    onRegionChanged: { region in
                        updateMapRegion(region: region)
                    }
                )
                .ignoresSafeArea(edges: .top)
                
                // Delivery Type Picker Overlay
                VStack {
                    deliveryTypePicker
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    Spacer()
                }
                
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
                updateMapRegion()
            })
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
                        .fontWeight(.medium)
                        .foregroundColor(appState.deliveryType == type ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            appState.deliveryType == type
                                ? Color.red
                                : Color.clear
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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
            
            // City Label
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text("Москва")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            // Location Button
            Button {
                // TODO: Get current location
            } label: {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        // подняли выше, чтобы не накладывалось на панель адресов
        .padding(.bottom, 420)
    }
    
    // MARK: - Address List Sheet
    
    private var addressListSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Title
            HStack {
                Text("Мои адреса")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.top, 12)
            
            // Address List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(appState.savedAddresses) { address in
                        AddressRowWithDelete(
                            address: address,
                            isSelected: appState.selectedAddress?.id == address.id,
                            onSelect: {
                                appState.selectAddress(address)
                                updateMapRegion()
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
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Helpers
    
    private func updateMapRegion(region: MKCoordinateRegion) {
        withAnimation {
            mapRegion = region
        }
    }
    
    private func updateMapRegion() {
        if let address = appState.selectedAddress,
           let lat = address.latitude,
           let lon = address.longitude {
            withAnimation {
                mapRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
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
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173), // Москва центр
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isMapMoving = false
    @State private var detectedAddress: String = "Определяем адрес..."
    @State private var showAddressForm = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            // Map
            CenterTrackingMapView(
                region: $mapRegion,
                isMoving: $isMapMoving,
                onRegionChanged: { region in
                    geocodeLocation(region.center)
                }
            )
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
            
            // Bottom Sheet
            VStack {
                Spacer()
                
                addressBottomSheet
            }
            
            // My Location Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if let location = locationManager.lastLocation {
                            withAnimation {
                                mapRegion = MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 200)
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
            locationManager.requestPermission()
            geocodeLocation(mapRegion.center)
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detectedAddress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        if isMapMoving {
                            Text("Отпустите для выбора")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isMapMoving {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Confirm Button
                Button {
                    selectedCoordinate = mapRegion.center
                    showAddressForm = true
                } label: {
                    Text("Подтвердить адрес")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(detectedAddress == "Определяем адрес..." ? Color.gray : Color.red)
                        .cornerRadius(14)
                }
                .disabled(detectedAddress == "Определяем адрес...")
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Geocoding
    
    private func geocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let street = placemark.thoroughfare {
                    addressComponents.append(street)
                }
                if let building = placemark.subThoroughfare {
                    addressComponents.append(building)
                }
                
                if addressComponents.isEmpty {
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                }
                
                DispatchQueue.main.async {
                    detectedAddress = addressComponents.isEmpty ? "Адрес не определён" : addressComponents.joined(separator: ", ")
                }
            } else {
                DispatchQueue.main.async {
                    detectedAddress = "Адрес не определён"
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
        let currentCenter = mapView.region.center
        let newCenter = region.center
        let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
            .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))
        
        if distance > 100 {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithCenterTracking
        private var debounceTimer: Timer?
        
        init(_ parent: MapViewWithCenterTracking) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
            debounceTimer?.invalidate()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.parent.isMoving = false
                    self?.parent.region = mapView.region
                    self?.parent.onRegionChanged(mapView.region)
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
        let camera = YMKCameraPosition(
            target: YMKPoint(latitude: region.center.latitude, longitude: region.center.longitude),
            zoom: 14,
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
        guard let mapWindow = mapView.mapWindow else { return }
        let map = mapWindow.map
        let current = map.cameraPosition.target
        let distance = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
        if distance > 100 {
            let camera = YMKCameraPosition(
                target: YMKPoint(latitude: region.center.latitude, longitude: region.center.longitude),
                zoom: map.cameraPosition.zoom,
                azimuth: map.cameraPosition.azimuth,
                tilt: map.cameraPosition.tilt
            )
            let anim = YMKAnimation(type: .smooth, duration: 0)
            map.move(with: camera, animation: anim, cameraCallback: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, YMKMapCameraListener {
        var parent: YandexMapWithCenterTracking
        private var debounceTimer: Timer?
        
        init(_ parent: YandexMapWithCenterTracking) {
            self.parent = parent
        }
        
        func onCameraPositionChanged(
            with map: YMKMap,
            cameraPosition: YMKCameraPosition,
            cameraUpdateReason: YMKCameraUpdateReason,
            finished: Bool
        ) {
            DispatchQueue.main.async {
                self.parent.isMoving = !finished
            }
            
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                guard let self else { return }
                let newRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude),
                    span: self.parent.region.span
                )
                DispatchQueue.main.async {
                    self.parent.region = newRegion
                    self.parent.onRegionChanged(newRegion)
                    self.parent.isMoving = false
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
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let addressAdded = Notification.Name("addressAdded")
}
