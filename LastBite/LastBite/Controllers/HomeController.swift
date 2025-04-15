//
//  HomeController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine
import CoreLocation // Necesario si pasas el LocationManager

// --- Asumiendo que tienes estos modelos y servicios ---
// struct Store { let id: Int; let name: String; let logo: String; /* ... */ }
// struct Order { let order_id: Int; /* ... */ }
// struct CategoryItemData: Identifiable, Equatable { let id: UUID; let title: String; let imageName: String; let store: Store? } // Necesita ser Equatable para animación
// struct Order: Identifiable, Equatable { var id: Int { order_id }; let order_id: Int } // Necesita ser Identifiable y Equatable

// class StoreService { static let shared = StoreService(); /* ... métodos fetch ... */ }
// class OrderService { static let shared = OrderService(); /* ... métodos fetch y receive ... */ }
// class SignInUserService: ObservableObject { static let shared = SignInUserService(); @Published var userId: Int? }
// class LocationManager: ObservableObject { @Published var latitude: Double?; @Published var longitude: Double?; @Published var lastLocation: CLLocation? }
// --- Fin de Asunciones ---


// 1. Hacerlo ObservableObject
class HomeController: ObservableObject {

    // 2. Publicar el estado que necesita la vista
    @Published var storeItems: [CategoryItemData] = []
    @Published var nearbyStores: [CategoryItemData] = []
    @Published var forYouItems: [CategoryItemData] = []
    @Published var activeOrders: [Order] = []

    // Estados para UI (carga y errores)
    @Published var isLoading: Bool = false // Un indicador general o varios específicos
    @Published var errorMessage: String? = nil

    // 3. Dependencias (Inyectadas)
    private let signInService: SignInUserService
    private let locationManager: LocationManager // Recibe el manager para observar cambios
    private let storeService: StoreService
    private let orderService: OrderService
    private var cancellables = Set<AnyCancellable>() // Para observar cambios de ubicación

    // 4. Inicializador para inyectar dependencias
    init(
        signInService: SignInUserService,
        locationManager: LocationManager,
        storeService: StoreService = StoreService.shared, // Usar singletons o instancias inyectadas
        orderService: OrderService = OrderService.shared
    ) {
        self.signInService = signInService
        self.locationManager = locationManager
        self.storeService = storeService
        self.orderService = orderService
        print("🏠 HomeController initialized.")

        // 5. Observar cambios de ubicación desde el LocationManager inyectado
        subscribeToLocationUpdates()
    }

    // MARK: - Observation Setup
    private func subscribeToLocationUpdates() {
        print("🏠 Setting up location observation...")

        // 1. Combina los publicadores de $latitude y $longitude
        Publishers.CombineLatest(locationManager.$latitude, locationManager.$longitude)
            // 2. Opcional: Puedes quitar el nil inicial si no quieres reaccionar hasta tener valores
            // .compactMap { lat, lon -> (Double, Double)? in
            //     guard let lat = lat, let lon = lon else { return nil }
            //     return (lat, lon)
            // }
            // 3. Aplica debounce si todavía quieres esperar un poco después de que ambos cambien
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // O ajusta/elimina el debounce
            .sink { [weak self] (latitude, longitude) in // 4. Recibe la tupla (Double?, Double?)
                guard let self = self else { return }

                // 5. Asegúrate de que ambos valores no sean nil
                if let lat = latitude, let lon = longitude {
                    print("📍 HomeController observed valid location update: Lat: \(lat), Lon: \(lon)")
                    // 6. Crea el objeto CLLocation
                    let location = CLLocation(latitude: lat, longitude: lon)
                    // 7. Llama a tu función de fetch
                    self.fetchNearbyStores(location: location)
                } else {
                    // Opcional: Manejar el caso donde uno o ambos son nil después del debounce
                     print("📍 HomeController observed location update but lat/lon is nil.")
                }
            }
            .store(in: &cancellables) // Guarda la suscripción
    }


    // MARK: - Data Loading Methods

    /// Carga todos los datos iniciales necesarios para la vista.
    func loadInitialData() {
        print("🏠 Loading initial data...")
        // Podrías usar un indicador de carga general
        // DispatchQueue.main.async { self.isLoading = true }

        // Ejecuta todas las cargas iniciales
        // (Considera usar TaskGroup si quieres paralelizar y manejar errores/carga de forma conjunta)
        fetchStores()
        fetchTopStores()
        fetchNotReceivedOrders()

        // Opcional: Podrías querer esperar a que todas terminen para poner isLoading = false
    }

    func fetchStores() {
        // isLoading = true // O un isLoadingStores específico
        errorMessage = nil
        print("⏳ Fetching stores...")
        storeService.fetchStores { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // self.isLoading = false
                switch result {
                case .success(let stores):
                    // Mapeo dentro del controlador
                    self.storeItems = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                    print("✅ Stores fetched: \(self.storeItems.count)")
                case .failure(let error):
                    print("❌ Failed to fetch stores:", error.localizedDescription)
                    self.errorMessage = "Could not load stores."
                }
            }
        }
    }

    func fetchNearbyStores(location: CLLocation) {
        // isLoading = true // O isLoadingNearby
        errorMessage = nil
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        print("⏳ Fetching nearby stores (\(lat), \(lon))...")
        storeService.fetchNearbyStores(latitude: lat, longitude: lon) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // self.isLoading = false
                switch result {
                case .success(let stores):
                    self.nearbyStores = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                     print("✅ Nearby stores fetched: \(self.nearbyStores.count)")
                case .failure(let error):
                    print("❌ Failed to fetch nearby stores:", error.localizedDescription)
                    // Podrías no querer mostrar un error si solo falla la ubicación
                    // self.errorMessage = "Could not load nearby stores."
                }
            }
        }
    }

    func fetchTopStores() {
        // isLoading = true // O isLoadingForYou
        errorMessage = nil
        print("⏳ Fetching top stores...")
        storeService.fetchTopStores { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                 // self.isLoading = false
                switch result {
                case .success(let stores):
                    self.forYouItems = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                    print("✅ Top stores fetched: \(self.forYouItems.count)")
                case .failure(let error):
                    print("❌ Failed to fetch top stores:", error.localizedDescription)
                    self.errorMessage = "Could not load recommendations."
                }
            }
        }
    }

    func fetchNotReceivedOrders() {
        guard let userId = signInService.userId else {
            print("ℹ️ Cannot fetch orders, user not logged in.")
            self.activeOrders = [] // Limpia si no hay usuario
            return
        }
        // isLoading = true // O isLoadingOrders
        errorMessage = nil
        print("⏳ Fetching active orders for user \(userId)...")
        orderService.fetchNotReceivedOrdersForUser(userId: userId) { [weak self] result in
             guard let self = self else { return }
            DispatchQueue.main.async {
                // self.isLoading = false
                switch result {
                case .success(let orders):
                    self.activeOrders = orders
                    print("✅ Active orders fetched: \(self.activeOrders.count)")
                case .failure(let error):
                    print("❌ Failed to fetch not received orders:", error.localizedDescription)
                    self.errorMessage = "Could not load active orders."
                    self.activeOrders = [] // Limpia si falla
                }
            }
        }
    }

    // MARK: - Action Methods

    func receiveOrder(orderId: Int) {
        // Podrías añadir un estado de carga específico para esta acción si quieres
        print("📦 Marking order \(orderId) as received...")
        orderService.receiveOrder(orderId: orderId) { [weak self] result in
             guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Order \(orderId) marked as received. Refreshing list...")
                    // Refresca la lista de órdenes activas en lugar de modificarla localmente
                    self.fetchNotReceivedOrders()
                case .failure(let error):
                    print("❌ Failed to mark order as received:", error.localizedDescription)
                     self.errorMessage = "Failed to update order status."
                }
            }
        }
    }

    // Opcional: Método para búsqueda (si mueves la lógica aquí)
    // func searchStores(query: String) { ... }
}


// --- Define tus modelos aquí o impórtalos ---
// Asegúrate que sean Identifiable y Equatable si los usas con .animation o ForEach directamente
