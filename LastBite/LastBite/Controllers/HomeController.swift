//
//  HomeController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class HomeController: ObservableObject {
    private let networkMonitor: NetworkMonitor

    @Published var storeItems: [CategoryItemData] = []
    @Published var nearbyStores: [CategoryItemData] = []
    @Published var ownedStores: [CategoryItemData] = []
    @Published var forYouItems: [CategoryItemData] = []
    @Published var activeOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let signInService: SignInUserService
    private let locationManager: LocationManager
    private let storeRepository: HybridStoreRepository
    private let orderRepository: OrderRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        signInService: SignInUserService,
        locationManager: LocationManager,
        storeRepository: HybridStoreRepository,
        orderRepository: OrderRepository,
        networkMonitor: NetworkMonitor
    ) {
        self.signInService = signInService
        self.locationManager = locationManager
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
        self.networkMonitor = networkMonitor 
        print("🏠 HomeController initialized with ALL Repositories.")
        subscribeToLocationUpdates()
    }

    private func subscribeToLocationUpdates() {
        print("🏠 Setting up location observation...")
        locationManager.$latitude.combineLatest(locationManager.$longitude)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] (latitude, longitude) in
                guard let self = self else { return }
                if let lat = latitude, let lon = longitude {
                     print("📍 HomeController observed valid location update: Lat: \(lat), Lon: \(lon)")
                     let location = CLLocation(latitude: lat, longitude: lon)
                     Task { await self.fetchNearbyStores(location: location) }
                } else {
                     print("📍 HomeController observed location update but lat/lon is nil.")
                }
            }
            .store(in: &cancellables)
    }


    // MARK: - Data Loading Methods

    func                                                                                                                                                                                                                                  loadInitialData() {
        print("Primera Carga")
        guard !isLoading else { return }
        print("🏠 Loading initial data via Repositories...")
        isLoading = true
        errorMessage = nil
        guard let userId = signInService.userId else {
            print("❌ CartController: Cannot load cart, user not logged in.")
            self.errorMessage = "Please sign in to view your cart."
            self.isLoading = false
            return
        }

        Task {
            do {
                async let storesTaskResult = storeRepository.fetchStores()
                async let topStoresTaskResult = storeRepository.fetchTopStores()
                async let ordersTaskResult: () = fetchNotReceivedOrders()
                async let ownedStoresResult = storeRepository.fetchOwnedStores(for: userId)
                print("se actualizan los datos")

                // Espera resultados
                let fetchedStores = try await storesTaskResult
                let fetchedTopStores = try await topStoresTaskResult
                let fetchedOwnedStores = try await ownedStoresResult
                

                
                try await ordersTaskResult

                async let mappedStoreItems = Task.detached {
                             print("🧵 Mapping storeItems on a background thread.")
                             return fetchedStores.map { CategoryItemData(title: $0.name, imageName: $0.logo ?? "", store: $0, isOwned: false) }
                         }.value

                         async let mappedForYouItems = Task.detached {
                             print("🧵 Mapping forYouItems on a background thread.")
                             return fetchedTopStores.map { CategoryItemData(title: $0.name, imageName: $0.logo ?? "", store: $0, isOwned: false) }
                         }.value

                         async let mappedOwnedStores = Task.detached {
                             print("🧵 Mapping ownedStores on a background thread.")
                             return fetchedOwnedStores.map { CategoryItemData(title: $0.name, imageName: $0.logo ?? "", store: $0, isOwned: true) }
                         }.value
                         
                         self.storeItems = await mappedStoreItems
                         self.forYouItems = await mappedForYouItems
                         self.ownedStores = await mappedOwnedStores


                print("✅ Initial data loaded successfully.")

            } catch {
                print("❌ Failed to load initial data: \(error.localizedDescription)")
                self.errorMessage = "Failed to load new data. Please check your internet connection and try again."
            }
            self.objectWillChange.send()
            self.isLoading = false
        }
    }

    func fetchNearbyStores(location: CLLocation) async {
        print("⏳ Fetching nearby stores via Repository...")
        do {
            let stores = try await storeRepository.fetchNearbyStores(location: location)
            self.nearbyStores = stores.map { CategoryItemData(title: $0.name, imageName: $0.logo ?? "", store: $0, isOwned: false) }
            print("✅ Nearby stores fetched: \(self.nearbyStores.count)")
        } catch {
             print("❌ Failed to fetch nearby stores via Repository: \(error.localizedDescription)")
        }
    }
    //private func fetchStores() async throws -> [Store] { try await storeRepository.fetchStores() }
    //private func fetchTopStores() async throws -> [Store] { try await storeRepository.fetchTopStores() }


    func fetchNotReceivedOrders() async throws {
        guard let userId = signInService.userId else {
            self.activeOrders = [] // Limpia si no hay usuario
            print("ℹ️ Cannot fetch orders, user not logged in.")
            return
        }
        print("⏳ Fetching active orders via Repository for user \(userId)...")
        // Llama al repositorio directamente
        let orders = try await orderRepository.fetchNotReceivedOrders(userId: userId)
        self.activeOrders = orders // Actualiza la propiedad publicada
        print("✅ Active orders fetched via Repository: \(self.activeOrders.count)")
    }

    func receiveOrder(orderId: Int) async {
        print("📦 Marking order \(orderId) as received via Repository...")
        self.errorMessage = nil // Limpia errores antes de intentar
        do {
            // Llama al repositorio
            try await orderRepository.markOrderAsReceived(orderId: orderId)
            print("✅ Order \(orderId) marked as received. Refreshing list...")
            // Refresca la lista llamando al método async de este controller
            try await self.fetchNotReceivedOrders()
        } catch {
             print("❌ Failed to mark/refresh order as received: \(error.localizedDescription)")
             self.errorMessage = "Failed to update order status."
        }
    }
    
    func refreshNearbyStoresManually() {
        print("🔄 Manual refresh of nearby stores requested.")

        // ✅ Forzar que comience a buscar una nueva ubicación
        locationManager.startUpdating()

        // Esperar un poco para que la ubicación se actualice
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let lat = self.locationManager.latitude, let lon = self.locationManager.longitude {
                print("📍 Current Location before fetch: Lat: \(lat), Lon: \(lon)")
                let location = CLLocation(latitude: lat, longitude: lon)
                Task {
                    await self.fetchNearbyStores(location: location)
                }
            } else {
                print("⚠️ Cannot refresh: location is not available.")
                self.errorMessage = "Location not available. Try again later."
            }
        }
    }

    
    @MainActor // Asegurar que se llama desde el hilo principal si actualiza UI o propiedades @Published directamente
    func synchronizeAllPendingData() async {
        // Usar la instancia de NetworkMonitor que HomeController ya tiene o una global/compartida
        // Asumiré que tienes acceso a NetworkMonitor.shared o una instancia inyectada.
        // Si networkMonitor es una propiedad de HomeController: self.networkMonitor.isConnected
        
        guard self.networkMonitor.isConnected else { // Asegúrate que NetworkMonitor.shared sea tu forma real de acceder
            print("🏠 HomeController: Sincronización abortada (offline).")
            // self.errorMessage = "No hay conexión para sincronizar." // Opcional
            return
        }
        
        print("🔄 HomeController: Intentando sincronizar datos pendientes de tiendas...")
        // self.isLoading = true // Podrías querer un estado de carga específico para la sincronización
        // self.errorMessage = nil

        do {
            // Llama al método del StoreRepository (que es el HybridStoreRepository)
            let (updated, deleted, images, created) = try await storeRepository.synchronizePendingStores()
            
            print("🔄 HomeController: Sincronización de tiendas completada. Actualizadas: \(updated), Borradas: \(deleted), Imágenes: \(images), Creadas: \(created).")
            
            if updated > 0 || deleted > 0 || images > 0 || created > 0 {
                print("🔄 HomeController: Hubo cambios sincronizados en tiendas, recargando datos iniciales...")
                // No necesitas establecer successMessage aquí si la UI no lo va a mostrar,
                // o si el StoreController (si se usara para sync) lo hiciera.
                // Pero si HomeController tiene su propio successMessage para esto:
                // self.successMessage = "Datos de tiendas sincronizados."
                
                loadInitialData() // Recargar para reflejar los cambios sincronizados
            } else {
                print("🔄 HomeController: No hay datos de tiendas pendientes para sincronizar.")
                // self.successMessage = "Datos de tiendas ya estaban actualizados."
            }
            
            // Aquí podrías añadir la sincronización para otros repositorios si fuera necesario
            // Ejemplo: if let cartRepo = self.cartRepository as? HybridCartRepository { ... }

        } catch {
            print("❌ HomeController: Fallo la sincronización de tiendas: \(error.localizedDescription)")
            self.errorMessage = "Fallo durante la sincronización de datos de tiendas."
        }
        // self.isLoading = false
    }

}
