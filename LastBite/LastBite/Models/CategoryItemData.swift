//
//  CategoryItemData.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import Foundation

// Asumimos que tu struct 'Store' (del artifact 'swift_store_model_final')
// ya conforma a Codable, Identifiable, y Equatable correctamente.
// struct Store: Codable, Identifiable, Equatable {
//     let store_id: Int
//     let name: String
//     var logo: String? // Importante que sea opcional
//     // ... otras propiedades ...
// }

struct CategoryItemData: Identifiable, Equatable {

    // Propiedad 'id' para conformar a Identifiable.
    // Genera un ID único y estable.
    var id: String {
        if let store = store {
            return "store_\(store.store_id)" // ID basado en el ID de la tienda
        } else {
            // Para items sin tienda, el ID se basa en el título.
            // Reemplazar espacios y convertir a minúsculas para un ID más robusto.
            return "title_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }
    }

    let title: String
    let imageName: String? // URL de la imagen, opcional para coincidir con store.logo
    var store: Store?      // La tienda asociada, opcional
    let isOwned: Bool      // Indica si la tienda es propiedad del usuario

    // Implementación de '==' para conformar a Equatable.
    // Esto es crucial para que SwiftUI detecte cambios de contenido y actualice la UI.
    static func == (lhs: CategoryItemData, rhs: CategoryItemData) -> Bool {
        // 1. Los IDs deben coincidir. Si no, definitivamente no son iguales.
        guard lhs.id == rhs.id else { return false }

        // 2. Si los IDs coinciden, compara el contenido relevante que podría cambiar visualmente.
        return lhs.title == rhs.title &&
               lhs.imageName == rhs.imageName && // Compara la URL de la imagen
               lhs.isOwned == rhs.isOwned &&
               lhs.store == rhs.store           // Compara las tiendas asociadas (requiere Store: Equatable)
    }
    
    // Inicializador de conveniencia para crear CategoryItemData a partir de un objeto Store.
    // Asegura que 'title' e 'imageName' se deriven consistentemente de 'store'.
    init(store: Store, isOwned: Bool) {
        self.store = store
        self.title = store.name          // El título del item es el nombre de la tienda
        self.imageName = store.logo      // El imageName es el logo de la tienda (que es String?)
        self.isOwned = isOwned
        // El 'id' se computará automáticamente usando store.store_id.
    }

    // Inicializador para items que podrían no tener una tienda asociada (si es un caso de uso válido)
    // o si necesitas establecer title/imageName independientemente de una tienda.
    init(title: String, imageName: String?, store: Store? = nil, isOwned: Bool = false) {
        self.title = title
        self.imageName = imageName
        self.store = store
        self.isOwned = isOwned
        // El 'id' se computará usando el título si no hay tienda, o store_id si la hay.
    }
}
