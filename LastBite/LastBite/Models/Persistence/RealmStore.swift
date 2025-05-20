//
//  RealmStore.swift
//  LastBite
//
//  Created by Andrés Romero on 17/05/25.
//

import Foundation
import RealmSwift

// Objeto Realm correspondiente a tu struct Store
class RealmStore: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var store_id: Int
    @Persisted var nit: String = ""
    @Persisted var name: String = ""
    @Persisted var address: String = ""
    @Persisted var longitude: Double = 0.0
    @Persisted var latitude: Double = 0.0
    @Persisted var logo: String?
    @Persisted var opens_at: String = "" // Formato "HH:mm:ss"
    @Persisted var closes_at: String = "" // Formato "HH:mm:ss"
    
    // Campos de auditoría (opcionales, como en tu struct)
    @Persisted var created_at: String?
    @Persisted var updated_at: String?
    
    // Campo para owner_id si lo necesitas para filtrar "tiendas propias" localmente.
    // Si no es parte del modelo 'Store' directamente, puedes omitirlo o añadirlo aquí
    // si el backend lo provee al obtener las tiendas y quieres cachearlo.
    // Por ahora, lo comentaré. Si lo necesitas, descoméntalo y ajústalo.
    // @Persisted var owner_id: Int?

    // Flags para la lógica de sincronización offline
    @Persisted var needsSyncUpdate: Bool = false // True si se actualizó offline y necesita sincronización con la API
    @Persisted var needsSyncDelete: Bool = false // True si se eliminó offline y necesita sincronización con la API
    @Persisted var pendingImageBase64: String?   // Almacena el base64 de una NUEVA imagen seleccionada offline

    // Convenience initializer para crear un RealmStore desde un objeto Store (del dominio)
    convenience init(from store: Store, needsSyncUpdate: Bool = false, needsSyncDelete: Bool = false, pendingImageBase64: String? = nil) {
        self.init()
        self.store_id = store.store_id
        self.nit = store.nit
        self.name = store.name
        self.address = store.address
        self.longitude = store.longitude
        self.latitude = store.latitude
        self.logo = store.logo
        self.opens_at = store.opens_at
        self.closes_at = store.closes_at
        self.created_at = store.created_at
        self.updated_at = store.updated_at
        
        self.needsSyncUpdate = needsSyncUpdate
        self.needsSyncDelete = needsSyncDelete
        self.pendingImageBase64 = pendingImageBase64
    }

    // Método para convertir un RealmStore de vuelta a un objeto Store (del dominio)
    func toDomainModel() -> Store {
        return Store(
            store_id: self.store_id,
            nit: self.nit,
            name: self.name,
            address: self.address,
            longitude: self.longitude,
            latitude: self.latitude,
            logo: self.logo,
            opens_at: self.opens_at,
            closes_at: self.closes_at,
            created_at: self.created_at,
            updated_at: self.updated_at
        )
    }
}
