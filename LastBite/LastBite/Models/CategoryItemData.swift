//
//  CategoryItemData.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import Foundation

// Asegúrate de que tu struct 'Store' también sea Equatable
// struct Store: /* ..., */ Equatable {
//     let id: Int // O el tipo de ID que uses
//     // ... otras propiedades ...
//
//     // Swift puede generar '==' automáticamente si todas las propiedades son Equatable
//     // O impleméntalo manualmente si es necesario:
//     static func == (lhs: Store, rhs: Store) -> Bool {
//         return lhs.id == rhs.id // Compara por ID usualmente
//     }
// }


struct CategoryItemData: Identifiable, Equatable { // Mantiene conformancia

    // 1. Define un 'id' ESTABLE para Identifiable
    //    Usamos el ID de la tienda si existe, sino el título.
    //    Asegúrate de que esto sea único para los items en tus listas.
    var id: String {
        if let store = store {
            // Un prefijo ayuda a evitar colisiones si tienes items sin tienda con el mismo nombre que un ID de tienda
            return "store_\(store.store_id)"
        } else {
            return "title_\(title)" // Usa el título si no hay tienda
        }
    }

    let title: String
    let imageName: String
    var store: Store? = nil // La tienda asociada (opcional)
    let isOwned: Bool

    // 2. Implementa '==' manualmente para Equatable
    static func == (lhs: CategoryItemData, rhs: CategoryItemData) -> Bool {
        // Define cuándo dos CategoryItemData representan lo mismo para la UI/animación
        // Opción A: Basado en la identidad (misma tienda o mismo título si no hay tienda)
         return lhs.id == rhs.id

        // Opción B: Más detallada (si quieres que cambie si el título o imagen cambia para la misma tienda ID)
        // guard lhs.id == rhs.id else { return false } // Deben tener la misma identidad primero
        // return lhs.title == rhs.title &&
        //        lhs.imageName == rhs.imageName &&
        //        lhs.store == rhs.store // Compara las tiendas (requiere Store: Equatable)
    }
}
