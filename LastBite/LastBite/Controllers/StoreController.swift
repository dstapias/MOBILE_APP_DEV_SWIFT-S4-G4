//
//  StoreController.swift
//  LastBite
//
//  Created by Andrés Romero on 13/05/25.
//

import Foundation

class StoreController: ObservableObject {
    private let storeRepository: HybridStoreRepository
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    private let networkMonitor: NetworkMonitor
    
    init(
        storeRepository: HybridStoreRepository, networkMonitor: NetworkMonitor
    ) {
        self.storeRepository = storeRepository
        self.networkMonitor = networkMonitor
        print("📦 StoreController initialized")
    }
    
    @MainActor
    func updateStore(
        store_id: Int,
        name: String,
        nit: String,
        imageBase64: String?,
        address: String,
        latitude: Double,
        longitude: Double,
        opens_at: String,
        closes_at: String
    ) async {
        print("🚀 Starting store update...")
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
       

        do {
            // 1. Subir imagen a Firebase y obtener URL
            // Paso 1: Subir la imagen a Firebase SI se proporcionó una nueva imagen Base64 VÁLIDA.
            // 2. Crear solicitud con la URL obtenida
            let storeRequest = StoreUpdateRequest(
                    name: name,
                nit: nit,
                address: address,
                longitude: longitude,
                latitude: latitude,
                logo: imageBase64,
                opens_at: opens_at,
                closes_at: closes_at,
            )

            // 3. Enviar al backend
            try await storeRepository.updateStore(storeRequest, store_id: store_id)
            print("✅ Store updated successfully.")
            self.successMessage = "Store updated successfully."
            self.errorMessage = nil

        } catch let error as ServiceError {
            print("❌ Service error updating store: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            if error.isNetworkConnectionError && !networkMonitor.isConnected {
                 self.successMessage = nil // Borrar mensaje de éxito si hubo error.
            }

        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            self.errorMessage = "Unexpected error occurred."
            self.successMessage = nil
        }
        self.isLoading = false
    }
    
    
    @MainActor
    func deleteStore(
        store_id: Int
    ) async {
        print("🚀 Deleting store...")
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        do {
            // 3. Enviar al backend
            try await storeRepository.deleteStore(store_id: store_id)
            if networkMonitor.isConnected {
                self.successMessage = "Tienda eliminada exitosamente."
            } else {
                self.successMessage = "Tienda marcada para eliminar localmente. Se sincronizará cuando haya conexión."
            }
            print("✅ Store deleted successfully.")

        } catch let error as ServiceError {
            print("❌ Service error deleting store: \(error.localizedDescription)")
            self.errorMessage = "Fallo al eliminar: \(error.localizedDescription)"
             if error.isNetworkConnectionError && !networkMonitor.isConnected {
                 self.successMessage = nil
             }

        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            self.errorMessage = "Unexpected error occurred."
            self.successMessage = nil
        }
        self.isLoading = false
    }
    
    @MainActor
    func fetchStoreById(store_id: Int) async throws -> Store {
        do {
            return try await storeRepository.fetchStoreById(store_id: store_id)
        }
    }
    
    /// Dispara la sincronización de todas las tiendas pendientes (actualizaciones y borrados).
        func synchronizePendingStores() async {
            guard !isLoading else {
                print("🛍️ StoreController: Sincronización ya en progreso o controlador ocupado.")
                return
            }
            guard await networkMonitor.isConnected else {
                print("🛍️ StoreController: No hay conexión a internet para sincronizar.")
                self.errorMessage = "No hay conexión para sincronizar." // Opcional: informar al usuario
                return
            }
            
            print("🔄 StoreController: Intentando sincronizar tiendas pendientes...")
            self.isLoading = true
            self.errorMessage = nil // Limpiar errores previos
            self.successMessage = nil // Limpiar mensajes de éxito previos
            
            do {
                let (updatedCount, deletedCount, imagesUploadedCount) = try await storeRepository.synchronizePendingStores()
                
                var messages: [String] = []
                if updatedCount > 0 { messages.append("\(updatedCount) actualiz.") }
                if deletedCount > 0 { messages.append("\(deletedCount) elimin.") }
                if imagesUploadedCount > 0 { messages.append("\(imagesUploadedCount) imág. subidas") }

                if messages.isEmpty {
                    self.successMessage = "No hay cambios pendientes en tiendas para sincronizar."
                } else {
                    self.successMessage = "Sincronización: " + messages.joined(separator: ", ") + "."
                }
                print("✅ StoreController: Sincronización completada. \(self.successMessage ?? "")")
                
                // Opcional: Si la sincronización resultó en cambios, podrías querer
                // notificar a otras partes de la app para que recarguen datos.
                // if updatedCount > 0 || deletedCount > 0 {
                // NotificationCenter.default.post(name: .didSyncStores, object: nil)
                // }

            } catch {
                print("❌ StoreController: Fallo en la sincronización de tiendas pendientes: \(error.localizedDescription)")
                self.errorMessage = "Fallo en la sincronización: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    
}
