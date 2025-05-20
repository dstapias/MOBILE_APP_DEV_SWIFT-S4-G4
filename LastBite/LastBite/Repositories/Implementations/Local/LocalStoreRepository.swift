//
//  LocalStoreRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 17/05/25.
//

import RealmSwift
import Foundation

// Es buena práctica definir errores específicos del repositorio local si es necesario,
// aunque muchos errores de Realm se pueden propagar directamente o convertir a errores de servicio más genéricos.
enum LocalStoreRepositoryError: Error {
    case realmInitializationFailed
    case objectNotFound
    case writeFailed(Error)
}

@MainActor // Marcamos la clase para que sus métodos se ejecuten en el actor principal por defecto,
            // lo cual es seguro para operaciones de UI y la mayoría de las escrituras simples en Realm.
            // Para escrituras más largas o en background, se pueden usar Tasks.detached o asyncWrite de Realm.
class LocalStoreRepository {

    // Helper para obtener una instancia de Realm.
    // Puede lanzar un error si Realm no se puede inicializar.
    private func getRealmInstance() throws -> Realm {
        do {
            return try Realm()
        } catch {
            print("❌ Error al inicializar Realm: \(error.localizedDescription)")
            // Podrías registrar este error con más detalle si es necesario.
            throw LocalStoreRepositoryError.realmInitializationFailed
        }
    }

    // MARK: - Operaciones de Guardado y Actualización

    /// Guarda una única tienda en Realm. Si la tienda ya existe (basado en su store_id), se actualiza.
    /// También puede establecer los flags de sincronización y la imagen pendiente.
    func saveStore(store: Store, needsSyncUpdate: Bool = false, needsSyncDelete: Bool = false, pendingImageBase64: String? = nil) async throws {
        let realm = try getRealmInstance()
        let realmStore = RealmStore(from: store, needsSyncUpdate: needsSyncUpdate, needsSyncDelete: needsSyncDelete, pendingImageBase64: pendingImageBase64)
        
        do {
            try realm.write {
                realm.add(realmStore, update: .modified) // .modified asegura que se actualice si ya existe
                print("🛍️ LocalStoreRepo: Guardada/Actualizada tienda \(store.store_id) localmente. Update: \(needsSyncUpdate), Delete: \(needsSyncDelete), PendingImg: \(pendingImageBase64 != nil)")
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al escribir/guardar tienda \(store.store_id): \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }

    /// Guarda un array de tiendas en Realm. Útil después de obtener datos de la API.
    /// Asume que estas tiendas vienen de la API, por lo que no necesitan sincronización inicialmente.
    func saveStores(stores: [Store]) async throws {
        guard !stores.isEmpty else {
            print("🛍️ LocalStoreRepo: No hay tiendas para guardar en lote.")
            return
        }
        let realm = try getRealmInstance()
        
        do {
            try realm.write {
                for store in stores {
                    let realmStore = RealmStore(from: store) // needsSync flags son false por defecto
                    realm.add(realmStore, update: .modified)
                }
                print("🛍️ LocalStoreRepo: Lote guardado de \(stores.count) tiendas localmente.")
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al escribir/guardar lote de tiendas: \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }

    // MARK: - Operaciones de Obtención (Fetch)

    /// Obtiene una tienda específica por su ID. Devuelve `nil` si no se encuentra.
    func fetchStoreById(id: Int) async throws -> Store? {
        let realm = try getRealmInstance()
        // Buscamos el objeto RealmStore por su clave primaria.
        // Lo congelamos (`.freeze()`) para hacerlo seguro entre hilos y evitar problemas con el actor principal.
        if let realmStore = realm.object(ofType: RealmStore.self, forPrimaryKey: id)?.freeze() {
            // Verificamos si el objeto congelado es inválido (podría haber sido borrado mientras tanto).
            return realmStore.isInvalidated ? nil : realmStore.toDomainModel()
        }
        return nil
    }

    /// Obtiene todas las tiendas que no están marcadas para borrado (`needsSyncDelete == false`).
    func fetchAllStores() async throws -> [Store] {
        let realm = try getRealmInstance()
        let realmStores = realm.objects(RealmStore.self)
            .filter("needsSyncDelete == false") // Excluir las que están pendientes de borrado
            .freeze() // Congelar la colección
        
        return realmStores.map { $0.toDomainModel() }
    }
    
    // Si decides implementar `owner_id` en `RealmStore`:
    /*
    /// Obtiene todas las tiendas pertenecientes a un `ownerId` específico que no están marcadas para borrado.
    func fetchOwnedStores(for ownerId: Int) async throws -> [Store] {
        let realm = try getRealmInstance()
        let realmStores = realm.objects(RealmStore.self)
            .filter("owner_id == %@ AND needsSyncDelete == false", ownerId)
            .freeze()
        return realmStores.map { $0.toDomainModel() }
    }
    */

    // MARK: - Operaciones para Sincronización Offline

    /// Marca una tienda para actualización. Actualiza sus datos localmente y establece `needsSyncUpdate = true`.
    /// `storeData`: Contiene los campos que se quieren actualizar.
    /// `newImageBase64`: Contiene el base64 de una *nueva* imagen seleccionada offline.
    func markStoreForUpdate(storeId: Int, storeData: StoreUpdateRequest, newImageBase64: String?) async throws {
        let realm = try getRealmInstance()
        do {
            try realm.write {
                guard let realmStore = realm.object(ofType: RealmStore.self, forPrimaryKey: storeId) else {
                    print("⚠️ LocalStoreRepo: Tienda \(storeId) no encontrada para marcar como actualizada.")
                    // Podrías lanzar un error si consideras esto un fallo crítico.
                    // throw LocalStoreRepositoryError.objectNotFound
                    return // O simplemente no hacer nada si no se encuentra.
                }

                // Actualizar campos de la tienda según `storeData`
                if let name = storeData.name { realmStore.name = name }
                if let nit = storeData.nit { realmStore.nit = nit }
                if let address = storeData.address { realmStore.address = address }
                if let lat = storeData.latitude { realmStore.latitude = lat }
                if let lon = storeData.longitude { realmStore.longitude = lon }
                if let opens = storeData.opens_at { realmStore.opens_at = opens }
                if let closes = storeData.closes_at { realmStore.closes_at = closes }
                
                // Manejo del logo y la imagen pendiente
                if let base64 = newImageBase64, !base64.isEmpty {
                    // Hay una nueva imagen seleccionada offline
                    realmStore.pendingImageBase64 = base64
                    // Opcional: podrías querer limpiar realmStore.logo aquí o poner un placeholder local
                    // si la UI depende de ello antes de la sincronización.
                    // Por ahora, `pendingImageBase64` indica que hay una nueva imagen.
                    print("🛍️ LocalStoreRepo: Imagen base64 pendiente guardada para tienda \(storeId).")
                } else if storeData.logo == "" { // Solicitud explícita para eliminar el logo
                    realmStore.logo = nil
                    realmStore.pendingImageBase64 = nil // Limpiar cualquier imagen pendiente anterior
                    print("🛍️ LocalStoreRepo: Logo marcado para eliminación para tienda \(storeId).")
                } else if let newLogoUrl = storeData.logo, !isBase64String(newLogoUrl) {
                    // Si `storeData.logo` es una URL (no base64) y no hay `newImageBase64`,
                    // significa que se quiere usar esta URL como el logo (podría ser la misma o una diferente
                    // si la URL se obtuvo de alguna otra manera que no sea subida de base64 en este flujo).
                    realmStore.logo = newLogoUrl
                    realmStore.pendingImageBase64 = nil // No hay imagen base64 pendiente si se especifica una URL.
                }
                // Si `storeData.logo` es nil y `newImageBase64` es nil, no se modifica `realmStore.logo` ni `pendingImageBase64`.

                realmStore.updated_at = ISO8601DateFormatter().string(from: Date()) // Actualizar fecha de modificación local
                realmStore.needsSyncUpdate = true
                realmStore.needsSyncDelete = false // Asegurarse de que no esté marcada para borrado
                print("🛍️ LocalStoreRepo: Marcada tienda \(storeId) para ACTUALIZACIÓN local. Logo actual: \(realmStore.logo ?? "nil"), ¿Base64 Pendiente?: \(realmStore.pendingImageBase64 != nil)")
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al marcar tienda \(storeId) para actualización: \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }

    /// Marca una tienda para ser borrada en la próxima sincronización.
    func markStoreForDelete(storeId: Int) async throws {
        let realm = try getRealmInstance()
        do {
            try realm.write {
                guard let realmStore = realm.object(ofType: RealmStore.self, forPrimaryKey: storeId) else {
                    print("⚠️ LocalStoreRepo: Tienda \(storeId) no encontrada para marcar como borrada.")
                    // throw LocalStoreRepositoryError.objectNotFound
                    return
                }
                realmStore.needsSyncDelete = true
                realmStore.needsSyncUpdate = false // Borrado tiene precedencia sobre actualización pendiente
                realmStore.pendingImageBase64 = nil // No subir imagen si se va a borrar
                print("🛍️ LocalStoreRepo: Marcada tienda \(storeId) para BORRADO local.")
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al marcar tienda \(storeId) para borrado: \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }

    /// Limpia los flags de sincronización de una tienda y su imagen pendiente.
    /// Se llama después de una *actualización* exitosa con la API.
    /// `newLogoUrlFromServer`: Si la API devolvió una nueva URL para el logo (ej. después de subir `pendingImageBase64`).
    func clearSyncFlagsAndPendingImage(storeId: Int, newLogoUrlFromServer: String? = nil) async throws {
        let realm = try getRealmInstance()
        do {
            try realm.write {
                guard let realmStore = realm.object(ofType: RealmStore.self, forPrimaryKey: storeId) else {
                    print("🛍️ LocalStoreRepo: Tienda \(storeId) no encontrada para limpiar flags (posiblemente ya borrada si la sincronización fue de borrado).")
                    return
                }
                
                // Solo limpiar si no está marcada para borrado, ya que este método es para post-actualización.
                if !realmStore.needsSyncDelete {
                    realmStore.needsSyncUpdate = false
                    realmStore.pendingImageBase64 = nil // Limpiar imagen base64 pendiente
                    
                    // Actualizar el logo con la URL del servidor si se proporcionó una.
                    // Esto es importante si 'pendingImageBase64' se subió y generó una nueva URL.
                    // Si 'newLogoUrlFromServer' es nil, pero 'storeData.logo' en la request original
                    // era "" (para borrar), entonces 'realmStore.logo' ya debería ser nil por 'markStoreForUpdate'.
                    // Si 'newLogoUrlFromServer' es una URL, la usamos.
                    if newLogoUrlFromServer != nil { // Acepta "" para borrar o una nueva URL
                        realmStore.logo = newLogoUrlFromServer
                    }
                    
                    print("🛍️ LocalStoreRepo: Limpiados flags de actualización e imagen pendiente para tienda \(storeId). Logo final: \(realmStore.logo ?? "nil")")
                }
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al limpiar flags para tienda \(storeId): \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }
    
    /// Elimina permanentemente una tienda de Realm.
    /// Se llama después de una *eliminación* exitosa con la API.
    func deleteStorePermanently(storeId: Int) async throws {
        let realm = try getRealmInstance()
        do {
            try realm.write {
                if let realmStore = realm.object(ofType: RealmStore.self, forPrimaryKey: storeId) {
                    realm.delete(realmStore)
                    print("🛍️ LocalStoreRepo: Borrada permanentemente tienda \(storeId) de Realm.")
                } else {
                    print("🛍️ LocalStoreRepo: Tienda \(storeId) no encontrada para borrado permanente (¿ya borrada?).")
                }
            }
        } catch {
            print("❌ LocalStoreRepo: Fallo al borrar permanentemente tienda \(storeId): \(error.localizedDescription)")
            throw LocalStoreRepositoryError.writeFailed(error)
        }
    }

    // MARK: - Obtener Tiendas para Sincronizar

    /// Devuelve un array de objetos `RealmStore` que necesitan ser actualizados en la API.
    /// Se devuelve `RealmStore` para poder acceder a `pendingImageBase64` si es necesario.
    func fetchStoresNeedingSyncUpdate() async throws -> [RealmStore] {
        let realm = try getRealmInstance()
        let realmStoresToUpdate = realm.objects(RealmStore.self)
            .filter("needsSyncUpdate == true AND needsSyncDelete == false")
            .freeze()
        return Array(realmStoresToUpdate) // Convertir a Array para pasar entre hilos/actores si es necesario.
    }

    /// Devuelve un array de `store_id` de tiendas que necesitan ser borradas de la API.
    func fetchStoreIdsNeedingSyncDelete() async throws -> [Int] {
        let realm = try getRealmInstance()
        let realmStoresToDelete = realm.objects(RealmStore.self)
            .filter("needsSyncDelete == true")
            .freeze()
        return realmStoresToDelete.map { $0.store_id }
    }
    
    // Helper para verificar si un string parece base64 (muy básico)
    private func isBase64String(_ string: String?) -> Bool {
        guard let str = string, !str.isEmpty else { return false }
        // Un string base64 de imagen suele ser largo y no empezar con http.
        // Esta es una heurística, no una validación completa.
        return str.count > 100 && !str.lowercased().hasPrefix("http")
    }
}
