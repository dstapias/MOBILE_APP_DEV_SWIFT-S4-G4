//
//  HybridStoreRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 17/05/25.
//

import Foundation
import CoreLocation // Para fetchNearbyStores

// Asumimos que tienes estos definidos en otra parte:
// protocol StoreRepository { ... } (ya lo definimos antes, asegúrate que esté accesible)
// class APIStoreRepository: StoreRepository { ... } (tu implementación para la API)
// class NetworkMonitor: ObservableObject { @Published var isConnected: Bool = true /* ... */ }
// class FirebaseService { static let shared = FirebaseService(); func uploadImageToFirebase(base64: String, fileName: String) async throws -> String { /* ... */ return "url_de_firebase/\(fileName)" } }
// enum ServiceError: Error { /* ... */ case offlineOperationFailed, network(Error), notFound, serverError(String), etc }


@MainActor
class HybridStoreRepository: StoreRepository {

    private let apiRepository: APIStoreRepository
    private let localRepository: LocalStoreRepository
    private let networkMonitor: NetworkMonitor
    private let firebaseService: FirebaseService // Para subir imágenes durante la sincronización

    init(apiRepository: APIStoreRepository,
         localRepository: LocalStoreRepository,
         networkMonitor: NetworkMonitor,
         firebaseService: FirebaseService = .shared) { // .shared si es un singleton
        self.apiRepository = apiRepository
        self.localRepository = localRepository
        self.networkMonitor = networkMonitor
        self.firebaseService = firebaseService
        print("📦 HybridStoreRepository initialized.")
    }

    // MARK: - Operaciones de Lectura (Fetch)

    func fetchStoreById(store_id: Int) async throws -> Store {
        if networkMonitor.isConnected {
            do {
                print("🛍️ HybridStoreRepo: Fetching store \(store_id) from API (online).")
                let store = try await apiRepository.fetchStoreById(store_id: store_id)
                try await localRepository.saveStore(store: store) // Actualizar caché local
                return store
            } catch let error where (error as? ServiceError)?.isNetworkConnectionError == true || (error is URLError && (error as! URLError).code == .notConnectedToInternet) {
                print("🛍️ HybridStoreRepo: API fetchStoreById \(store_id) failed (network error). Trying local.")
                if let localStore = try await localRepository.fetchStoreById(id: store_id) {
                    return localStore
                } else {
                    throw ServiceError.notFound // O un error más específico "no encontrado y offline"
                }
            } catch { // Otros errores de API (ej. 404 Not Found, 500 Server Error)
                print("🛍️ HybridStoreRepo: API fetchStoreById \(store_id) failed (non-network: \(error.localizedDescription)). Trying local as fallback.")
                if let localStore = try await localRepository.fetchStoreById(id: store_id) {
                    return localStore // Devolver local si existe, incluso con error de API no relacionado con red
                }
                throw error // Si no está en local, relanzar el error original de la API
            }
        } else { // Offline
            print("🛍️ HybridStoreRepo: Fetching store \(store_id) from Local (offline).")
            if let localStore = try await localRepository.fetchStoreById(id: store_id) {
                return localStore
            } else {
                throw ServiceError.emptyOffline // O notFound
            }
        }
    }

    func fetchStores() async throws -> [Store] {
        if networkMonitor.isConnected {
            do {
                print("🛍️ HybridStoreRepo: Fetching all stores from API (online).")
                let stores = try await apiRepository.fetchStores()
                try await localRepository.saveStores(stores: stores)
                return stores
            } catch let error where (error as? ServiceError)?.isNetworkConnectionError == true || (error is URLError && (error as! URLError).code == .notConnectedToInternet) {
                print("🛍️ HybridStoreRepo: API fetchStores failed (network error). Trying local.")
                return try await localRepository.fetchAllStores()
            } catch { // Otros errores de API
                print("🛍️ HybridStoreRepo: API fetchStores failed (non-network: \(error.localizedDescription)). Trying local as fallback.")
                return try await localRepository.fetchAllStores() // Fallback a local
            }
        } else { // Offline
            print("🛍️ HybridStoreRepo: Fetching all stores from Local (offline).")
            return try await localRepository.fetchAllStores()
        }
    }
    
    // Implementa fetchTopStores, fetchNearbyStores, fetchOwnedStores de manera similar:
    // API primero, luego guardar en local, y fallback a local si la API falla o está offline.
    // Para fetchNearbyStores, el fallback local puede no ser tan útil si los datos son muy dinámicos.

    func fetchTopStores() async throws -> [Store] {
        // Simplificado: misma lógica que fetchStores, la API debería devolver las "top"
        if networkMonitor.isConnected {
            do {
                let stores = try await apiRepository.fetchTopStores()
                try await localRepository.saveStores(stores: stores) // Guardarlas igual, podrían ser un subconjunto
                return stores
            } catch let error where (error as? ServiceError)?.isNetworkConnectionError == true || (error is URLError && (error as! URLError).code == .notConnectedToInternet) {
                 print("🛍️ HybridStoreRepo: API fetchTopStores failed (network). Using all local as fallback (simplification).")
                return try await localRepository.fetchAllStores() // O una lógica local para "top"
            } catch {
                 print("🛍️ HybridStoreRepo: API fetchTopStores failed (non-network). Using all local. Error: \(error.localizedDescription)")
                return try await localRepository.fetchAllStores()
            }
        } else {
             print("🛍️ HybridStoreRepo: Fetching 'top' stores from Local (offline, returns all).")
            return try await localRepository.fetchAllStores()
        }
    }

    func fetchNearbyStores(location: CLLocation) async throws -> [Store] {
        if networkMonitor.isConnected {
            do {
                let stores = try await apiRepository.fetchNearbyStores(location: location)
                try await localRepository.saveStores(stores: stores)
                return stores
            } catch let error where (error as? ServiceError)?.isNetworkConnectionError == true || (error is URLError && (error as! URLError).code == .notConnectedToInternet) {
                print("🛍️ HybridStoreRepo: API fetchNearbyStores failed (network). Nearby not available offline.")
                return [] // Datos de cercanía son muy volátiles para un caché simple offline
            } catch {
                print("🛍️ HybridStoreRepo: API fetchNearbyStores failed (non-network). Error: \(error.localizedDescription)")
                return []
            }
        } else {
            print("🛍️ HybridStoreRepo: Nearby stores not available (offline).")
            return []
        }
    }

    func fetchOwnedStores(for userId: Int) async throws -> [Store] {
        // Asumimos que owner_id no está en RealmStore directamente,
        // así que dependemos de la API para la lista de tiendas propias.
        // El LocalStoreRepository guardará estas tiendas, y fetchAllStores las devolvería si están ahí.
        // Una mejor caché local para "owned" podría implicar guardar la relación user-store.
        if networkMonitor.isConnected {
            do {
                print("🛍️ HybridStoreRepo: Fetching owned stores for user \(userId) from API (online).")
                let stores = try await apiRepository.fetchOwnedStores(for: userId)
                try await localRepository.saveStores(stores: stores) // Guardar/actualizar estas tiendas en el caché general
                return stores
            } catch let error where (error as? ServiceError)?.isNetworkConnectionError == true || (error is URLError && (error as! URLError).code == .notConnectedToInternet) {
                print("🛍️ HybridStoreRepo: API fetchOwnedStores failed (network). Trying to filter all local stores (simplification).")
                // Esto es una simplificación. Si owner_id estuviera en RealmStore, filtraríamos por él.
                // Como no está, no podemos saber cuáles son "propias" offline a menos que ya estén cacheadas de una llamada anterior.
                // Podríamos devolver todas las tiendas cacheadas, o las que se obtuvieron previamente para este usuario si tuviéramos esa info.
                // Por ahora, devolvemos un array vacío si falla por red, ya que no podemos garantizar "propiedad".
                return [] // O intentar obtenerlas del caché general si tienes una forma de identificarlas como "propias"
            } catch {
                 print("🛍️ HybridStoreRepo: API fetchOwnedStores failed (non-network). Error: \(error.localizedDescription)")
                 return [] // Similar al caso de error de red
            }
        } else {
            print("🛍️ HybridStoreRepo: Fetching owned stores for user \(userId) - not reliably possible offline without owner_id in local cache or specific caching strategy.")
            // Devolver las tiendas que ya se han guardado y podrían ser de este usuario, o vacío.
            // Si LocalStoreRepository tuviera fetchOwnedStores (basado en un owner_id en RealmStore), lo llamaríamos aquí.
            // Como no, devolvemos vacío.
            return []
        }
    }

    // MARK: - Operaciones de Escritura


    /// Actualiza una tienda.
    /// `storeRequest`: Contiene los campos a actualizar. `logo` puede ser:
    ///   - URL de una nueva imagen (si se subió a Firebase antes de llamar a este método).
    ///   - `""` para indicar que se debe eliminar el logo existente.
    ///   - `nil` para indicar que el logo no se modifica.
    ///   - Un string base64 (solo si se está operando offline y el `StoreController` lo pasa así).
    /// `store_id`: El ID de la tienda a actualizar.
    func updateStore(_ storeRequest: StoreUpdateRequest, store_id: Int) async throws {
        if networkMonitor.isConnected {
            var requestForApi = storeRequest
            // Si `storeRequest.logo` es un base64, significa que el StoreController
            // intentó subirlo, pero quizás falló, o es un flujo donde el controller no sube.
            // El Hybrid repo (online) debería intentar subirlo si es base64 ANTES de llamar a la API.
            var finalLogoUrlForApi: String? = storeRequest.logo

            if let logoValue = storeRequest.logo, isBase64String(logoValue) {
                print("🛍️ HybridStoreRepo (Online): storeRequest.logo es base64. Intentando subir a Firebase...")
                do {
                    let fileName = "store_logos/\(store_id)_\(UUID().uuidString).jpg"
                    finalLogoUrlForApi = try await firebaseService.uploadImageToFirebase(base64: logoValue, fileName: fileName)
                    print("📸 HybridStoreRepo (Online): Imagen subida. URL: \(finalLogoUrlForApi ?? "nil")")
                } catch {
                    print("❌ HybridStoreRepo (Online): Fallo al subir imagen base64 a Firebase: \(error.localizedDescription). Se actualizará la tienda sin cambiar la imagen.")
                    finalLogoUrlForApi = nil // No se pudo subir, así que no se cambia el logo en la API.
                }
            }
            requestForApi.logo = finalLogoUrlForApi // Actualizar el logo en la request para la API

            print("🛍️ HybridStoreRepo: Updating store \(store_id) via API (online). Logo para API: \(requestForApi.logo ?? "nil")")
            try await apiRepository.updateStore(requestForApi, store_id: store_id)
            
            // Después de actualizar en API, obtener la tienda actualizada de la API para asegurar consistencia local.
            // O, si la API no devuelve la tienda actualizada, construirla con los datos de la request.
            // Aquí asumimos que necesitamos reconstruirla o buscarla. Para simplicidad, la reconstruimos:
            let updatedStoreFromRequest = Store(
                store_id: store_id,
                nit: storeRequest.nit ?? "", // Necesitas los valores actuales o los que se enviaron
                name: storeRequest.name ?? "",
                address: storeRequest.address ?? "",
                longitude: storeRequest.longitude ?? 0.0,
                latitude: storeRequest.latitude ?? 0.0,
                logo: requestForApi.logo, // El logo final que se envió a la API
                opens_at: storeRequest.opens_at ?? "",
                closes_at: storeRequest.closes_at ?? "",
                created_at: nil, // Estos no se envían en update, se necesitaría un fetch para obtenerlos actualizados
                updated_at: ISO8601DateFormatter().string(from: Date()) // O el de la API si lo devuelve
            )
             // Guardar la versión actualizada (con el logo URL correcto) localmente y limpiar flags.
            try await localRepository.saveStore(store: updatedStoreFromRequest, needsSyncUpdate: false, pendingImageBase64: nil)
            print("🛍️ HybridStoreRepo: Tienda \(store_id) actualizada en API y local (online). Flags limpiados.")

        } else { // Offline
            print("🛍️ HybridStoreRepo: Updating store \(store_id) locally (offline).")
            var imageBase64ToSaveLocally: String? = nil
            if let logoValue = storeRequest.logo, isBase64String(logoValue) {
                imageBase64ToSaveLocally = logoValue // Guardar el base64 para sincronización posterior
            }
            // `storeRequest.logo` podría ser "" para borrar, o una URL existente que no se cambia.
            // `localRepository.markStoreForUpdate` manejará esto.
            try await localRepository.markStoreForUpdate(storeId: store_id, storeData: storeRequest, newImageBase64: imageBase64ToSaveLocally)
        }
    }

    func deleteStore(store_id: Int) async throws {
        print("🛍️ HybridStoreRepo: Marcando tienda \(store_id) para borrado local primero.")
        try await localRepository.markStoreForDelete(storeId: store_id)

        if networkMonitor.isConnected {
            print("🛍️ HybridStoreRepo: Intentando borrar tienda \(store_id) de API (online).")
            do {
                try await apiRepository.deleteStore(store_id: store_id)
                try await localRepository.deleteStorePermanently(storeId: store_id) // Borrar de Realm
                print("🛍️ HybridStoreRepo: Tienda \(store_id) borrada de API y localmente (online).")
            } catch {
                print("❌ HybridStoreRepo: Fallo al borrar tienda \(store_id) de API. Permanece marcada localmente. Error: \(error.localizedDescription)")
                throw error // Re-lanzar para que el controller lo maneje
            }
        } else {
            print("🛍️ HybridStoreRepo: Tienda \(store_id) marcada para borrado local (offline). Se sincronizará.")
            // No hay error que lanzar si estamos offline, la operación local fue "exitosa".
        }
    }

    // MARK: - Sincronización

    /// Sincroniza las tiendas pendientes (actualizaciones y borrados) con la API.
    /// Devuelve el número de operaciones exitosas.
    func synchronizePendingStores() async throws -> (updated: Int, deleted: Int, imagesUploaded: Int, created:Int) {
        guard networkMonitor.isConnected else {
            print("🛍️ HybridStoreRepo: Sincronización abortada (offline).")
            return (0, 0, 0, 0)
        }

        print("🔄 HybridStoreRepo: Iniciando sincronización de tiendas pendientes...")
        var successfulCreates = 0
        var successfulUpdates = 0
        var successfulDeletes = 0
        var successfulImageUploads = 0

        // 1. Sincronizar Actualizaciones
        let storesToUpdate = try await localRepository.fetchStoresNeedingSyncUpdate() // Devuelve [RealmStore]
        print("🔄 HybridStoreRepo: \(storesToUpdate.count) tiendas para actualizar.")
        for realmStore in storesToUpdate {
            var logoUrlForAPI: String? = realmStore.logo // Logo actual o el que ya fue subido y es una URL

            // Si hay una imagen base64 pendiente, subirla a Firebase AHORA
            if let base64 = realmStore.pendingImageBase64, !base64.isEmpty {
                print("📸 HybridStoreRepo (Sync): Subiendo imagen pendiente para tienda \(realmStore.store_id)...")
                do {
                    let fileName = "store_logos/\(realmStore.store_id)_\(UUID().uuidString)" // Nombre único
                    logoUrlForAPI = try await firebaseService.uploadImageToFirebase(base64: base64, fileName: fileName)
                    successfulImageUploads += 1
                    print("📸 HybridStoreRepo (Sync): Imagen subida para tienda \(realmStore.store_id). URL: \(logoUrlForAPI ?? "nil")")
                } catch {
                    print("❌ HybridStoreRepo (Sync): Fallo al subir imagen pendiente para tienda \(realmStore.store_id). Error: \(error.localizedDescription). Se intentará actualizar sin cambiar imagen esta vez.")
                    // `logoUrlForAPI` mantiene el valor anterior de `realmStore.logo`.
                    // La imagen base64 permanecerá en `pendingImageBase64` para el próximo intento de sync si esta actualización falla.
                    // Si esta actualización SÍ tiene éxito pero sin la imagen, el flag `pendingImageBase64` se limpiará abajo.
                    // Es importante que clearSyncFlagsAndPendingImage NO limpie pendingImageBase64 si la subida de imagen falló pero la actualización de datos sí pasó.
                    // Por ahora, si la subida falla, la actualización de la API se hará con el logoURL que ya tenía (o nil).
                }
            }
            
            let updateRequest = StoreUpdateRequest(
                name: realmStore.name, nit: realmStore.nit, address: realmStore.address,
                longitude: realmStore.longitude, latitude: realmStore.latitude,
                logo: logoUrlForAPI, // URL de Firebase o logo existente/nil o "" si se borró
                opens_at: realmStore.opens_at, closes_at: realmStore.closes_at
            )
            
            do {
                try await apiRepository.updateStore(updateRequest, store_id: realmStore.store_id)
                // Limpiar flags y la imagen pendiente (si se subió o si la actualización tuvo éxito sin ella)
                // Pasar `logoUrlForAPI` para que el logo local se actualice con la URL de la imagen recién subida.
                try await localRepository.clearSyncFlagsAndPendingImage(storeId: realmStore.store_id, newLogoUrlFromServer: logoUrlForAPI)
                successfulUpdates += 1
                print("✅ HybridStoreRepo (Sync): Actualización exitosa para tienda \(realmStore.store_id).")
            } catch {
                print("❌ HybridStoreRepo (Sync): Fallo al sincronizar actualización para tienda \(realmStore.store_id). Error: \(error.localizedDescription)")
                // No limpiar flags si la API falló, para reintentar después.
            }
        }

        // 2. Sincronizar Borrados
        let storeIdsToDelete = try await localRepository.fetchStoreIdsNeedingSyncDelete()
        print("🔄 HybridStoreRepo: \(storeIdsToDelete.count) tiendas para borrar.")
        for storeId in storeIdsToDelete {
            do {
                try await apiRepository.deleteStore(store_id: storeId)
                try await localRepository.deleteStorePermanently(storeId: storeId) // Eliminar de Realm
                successfulDeletes += 1
                print("✅ HybridStoreRepo (Sync): Borrado exitoso para tienda \(storeId).")
            } catch {
                print("❌ HybridStoreRepo (Sync): Fallo al sincronizar borrado para tienda \(storeId). Error: \(error.localizedDescription)")
                // No eliminar de local si la API falló, para reintentar después.
            }
        }
        
        
        
        // 0️⃣ Sincronizar Creaciones
        let storesToCreate = try await localRepository.fetchStoresNeedingSyncCreate()
        print("🔄 HybridStoreRepo: \(storesToCreate.count) tiendas para crear.")
        for realmStore in storesToCreate {
            // 1️⃣ Subir la imagen Base64 pendiente a Firebase (si existe)
            var finalLogoUrlForApi: String? = nil
            if let base64 = realmStore.pendingImageBase64,
               isBase64String(base64) {
                print("📸 HybridStoreRepo (Sync): Subiendo imagen pendiente para creación de tienda \(realmStore.store_id)...")
                do {
                    let fileName = "store_logos/new_\(realmStore.store_id)_\(UUID().uuidString).jpg"
                    finalLogoUrlForApi = try await firebaseService.uploadImageToFirebase(
                        base64: base64,
                        fileName: fileName
                    )
                    print("📸 Imagen subida. URL: \(finalLogoUrlForApi!)")
                } catch {
                    print("❌ HybridStoreRepo (Sync): Falló la subida de imagen para tienda \(realmStore.store_id): \(error). Creando sin logo.")
                    finalLogoUrlForApi = nil
                }
            }

            // 2️⃣ Construir el StoreCreateRequest con la URL final (o nil)
            let createReq = StoreCreateRequest(
                name:     realmStore.name,
                nit:      realmStore.nit,
                address:  realmStore.address,
                longitude: realmStore.longitude,
                latitude:  realmStore.latitude,
                logo:      finalLogoUrlForApi,          // aquí va la URL, no el Base64
                opens_at:  realmStore.opens_at,
                closes_at: realmStore.closes_at
            )

            // 3️⃣ Llamar a la API
            do {
                let created = try await apiRepository.createStore(createReq)

                // 4️⃣ Guardar la entidad real devuelta por el servidor
                try await localRepository.saveStore(
                    store: created,
                    needsSyncUpdate: false,
                    needsSyncDelete: false,
                    pendingImageBase64: nil
                )
                // 5️⃣ Limpiar la flag de creación
                try await localRepository.clearSyncCreateFlag(storeId: realmStore.store_id)

                successfulCreates += 1
                print("✅ HybridStoreRepo: Creación exitosa de tienda temporal \(realmStore.store_id) → \(created.store_id).")
            } catch {
                print("❌ HybridStoreRepo: Error al crear tienda pendiente \(realmStore.store_id): \(error)")
            }
        }
        print("🔄 HybridStoreRepo: Sincronización finalizada. Actualizadas: \(successfulUpdates), Borradas: \(successfulDeletes), Imágenes subidas: \(successfulImageUploads),  Creadas: \(successfulCreates).")
        return (successfulUpdates, successfulDeletes, successfulImageUploads, successfulCreates)
    }
    
    /// Crea una nueva tienda.
    func createStore(_ storeRequest: StoreCreateRequest) async throws -> Store {
        print("🚀 HybridStoreRepo: Starting store creation...")
        if networkMonitor.isConnected {
            var requestForApi = storeRequest
            var finalLogoUrlForApi: String? = storeRequest.logo

            // Si la imagen es Base64, subir a Firebase primero
            if let logoValue = storeRequest.logo, isBase64String(logoValue) {
                print("🛍️ HybridStoreRepo (Online): logo es base64. Subiendo a Firebase...")
                do {
                    let fileName = "store_logos/new_\(UUID().uuidString).jpg"
                    finalLogoUrlForApi = try await firebaseService.uploadImageToFirebase(base64: logoValue, fileName: fileName)
                    print("📸 Imagen subida. URL: \(finalLogoUrlForApi ?? "")")
                } catch {
                    print("❌ Falló subir imagen a Firebase: \(error.localizedDescription). Creando sin logo.")
                    finalLogoUrlForApi = nil
                }
            }
            requestForApi.logo = finalLogoUrlForApi

            // Llamada a la API para crear la tienda
            print("🛍️ HybridStoreRepo: Llamando API createStore con logo: \(requestForApi.logo ?? "nil")")
            let createdStore = try await apiRepository.createStore(requestForApi)

            // Guardar localmente la tienda creada
            try await localRepository.saveStore(store: createdStore)
            print("✅ HybridStoreRepo: Store creada y guardada localmente: \(createdStore)")
            return createdStore

        } else {
            print("🛍️ HybridStoreRepo: Offline. Marcando tienda para creación local.")
            // Marcar para creación local (implementación en LocalStoreRepository)
            let pendingStore = try await localRepository.markStoreForCreate(storeData: storeRequest, newImageBase64: storeRequest.logo)
            return pendingStore
        }
    }

    
    // Helper para verificar si un string parece base64 (muy básico)
    private func isBase64String(_ string: String?) -> Bool {
        guard let str = string, !str.isEmpty else { return false }
        return str.count > 100 && !str.lowercased().hasPrefix("http") && !str.lowercased().hasPrefix("file:") // Mejorado un poco
    }
}
