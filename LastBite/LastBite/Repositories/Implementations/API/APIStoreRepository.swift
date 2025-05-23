//
//  APIStoreRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import CoreLocation

// --- La Implementación Concreta ---
// Usa StoreService para obtener datos de la API.
class APIStoreRepository: StoreRepository {
    // 1. Conforma al protocolo

    // 2. Dependencia del Servicio (ahora con métodos async)
    private let storeService: StoreService

    // 3. Inicializador para inyectar el servicio
    init(storeService: StoreService = StoreService.shared) {
        self.storeService = storeService
        print(" GITHUB APIStoreRepository initialized.")
    }

    // 4. Implementación de los métodos del protocolo
    
    func updateStore(_ store: StoreUpdateRequest, store_id: Int) async throws {
        try await storeService.updateStoreAsync(store, store_id: store_id)
    }
    
    func deleteStore(store_id: Int) async throws {
        try await storeService.deleteStoreAsync(store_id)
    }

    func fetchStores() async throws -> [Store] {
        // Llama al método async del servicio directamente
        try await storeService.fetchStoresAsync()
    }

    func fetchNearbyStores(location: CLLocation) async throws -> [Store] {
        // Llama al método async del servicio directamente
        try await storeService.fetchNearbyStoresAsync(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    func fetchTopStores() async throws -> [Store] {
        // Llama al método async del servicio directamente
        try await storeService.fetchTopStoresAsync()
    }
    
    func fetchOwnedStores(for userId: Int) async throws -> [Store] {
        // Llama al método async del servicio directamente
        try await storeService.fetchOwnedStoresAsync(for: userId)
    }
    
    func fetchStoreById(store_id: Int) async throws -> Store {
        try await storeService.fetchStoreByIdAsync(store_id)
    }
    
    /// Crea una nueva tienda via API.
    /// - Parameter store: Datos de la tienda a crear.
    /// - Returns: El objeto Store creado.
    func createStore(_ store: StoreCreateRequest) async throws -> Store {
        try await storeService.createStoreAsync(store)
    }
    
}
