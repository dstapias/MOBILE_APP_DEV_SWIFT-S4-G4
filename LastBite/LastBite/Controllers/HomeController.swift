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

    @Published var storeItems: [CategoryItemData] = []
    @Published var nearbyStores: [CategoryItemData] = []
    @Published var forYouItems: [CategoryItemData] = []
    @Published var activeOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let signInService: SignInUserService
    private let locationManager: LocationManager
    private let storeRepository: StoreRepository
    private let orderRepository: OrderRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        signInService: SignInUserService,
        locationManager: LocationManager,
        storeRepository: StoreRepository,
        orderRepository: OrderRepository
    ) {
        self.signInService = signInService
        self.locationManager = locationManager
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
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

    func loadInitialData() {
        guard !isLoading else { return }
        print("🏠 Loading initial data via Repositories...")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Ejecuta todo en paralelo
                async let storesTaskResult = storeRepository.fetchStores()
                async let topStoresTaskResult = storeRepository.fetchTopStores()
                async let ordersTaskResult = fetchNotReceivedOrders() // Llama al método del controller

                // Espera resultados
                let fetchedStores = try await storesTaskResult
                let fetchedTopStores = try await topStoresTaskResult
                try await ordersTaskResult // Espera a que termine

                // Actualiza estado (ya estamos en @MainActor)
                self.storeItems = fetchedStores.map { CategoryItemData(title: $0.name, imageName: $0.logo, store: $0) }
                self.forYouItems = fetchedTopStores.map { CategoryItemData(title: $0.name, imageName: $0.logo, store: $0) }

                print("✅ Initial data loaded successfully.")

            } catch {
                print("❌ Failed to load initial data: \(error.localizedDescription)")
                self.errorMessage = "Failed to load new data. Please check your internet connection and try again."
            }
            self.isLoading = false
        }
    }

    func fetchNearbyStores(location: CLLocation) async {
        print("⏳ Fetching nearby stores via Repository...")
        do {
            let stores = try await storeRepository.fetchNearbyStores(location: location)
            self.nearbyStores = stores.map { CategoryItemData(title: $0.name, imageName: $0.logo, store: $0) }
            print("✅ Nearby stores fetched: \(self.nearbyStores.count)")
        } catch {
             print("❌ Failed to fetch nearby stores via Repository: \(error.localizedDescription)")
        }
    }
    private func fetchStores() async throws -> [Store] { try await storeRepository.fetchStores() }
    private func fetchTopStores() async throws -> [Store] { try await storeRepository.fetchTopStores() }


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
}
