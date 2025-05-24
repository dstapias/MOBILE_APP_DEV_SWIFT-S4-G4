//
//  StoreRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import CoreLocation // Necesario para fetchNearbyStores

// --- El Protocolo ---
// Define las operaciones que se pueden realizar sobre las tiendas.
protocol StoreRepository {
    /// Obtiene todas las tiendas principales.
    /// - Throws: Un error si la obtención falla (ej. ServiceError).
    /// - Returns: Un array de objetos Store.
    func fetchStores() async throws -> [Store]

    /// Obtiene las tiendas cercanas a una ubicación dada.
    /// - Parameter location: La ubicación CLLocation actual.
    /// - Throws: Un error si la obtención falla.
    /// - Returns: Un array de objetos Store cercanos.
    func fetchNearbyStores(location: CLLocation) async throws -> [Store]

    /// Obtiene las tiendas destacadas o "top".
    /// - Throws: Un error si la obtención falla.
    /// - Returns: Un array de objetos Store destacados.
    func fetchTopStores() async throws -> [Store]
    
    /// Obtiene las tiendas de asociadas a un usuario en especifico.
    /// - Throws: Un error si la obtención falla.
    /// - Returns: Un array de objetos Store
    func fetchOwnedStores(for userId: Int) async throws -> [Store]
        
    func updateStore(_ store: StoreUpdateRequest, store_id: Int) async throws
    
    func deleteStore(store_id: Int) async throws
    
    func fetchStoreById(store_id: Int) async throws -> Store
    
    /// Crea una nueva tienda.
    /// - Parameter store: Datos de la tienda a crear.
    /// - Returns: El objeto Store recién creado.
    func createStore(_ store: StoreCreateRequest) async throws -> Store
    
}
