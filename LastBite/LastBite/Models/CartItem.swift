//
//  CartItem.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// 1. Añade ', Equatable'
struct CartItem: Identifiable, Equatable {

    // 2. Cambia 'id' para usar una propiedad estable como 'productId'
    //    Esto hace que la identidad en SwiftUI sea consistente si recargas los datos.
    var id: Int { productId } // 'id' ahora es un Int y deriva de productId

    let productId: Int
    let name: String
    let detail: String
    var quantity: Int // 'var' es correcto para usar con $item en ForEach
    let price: Double
    let imageUrl: String

    // 3. Implementa manualmente la función '==' para Equatable
    //    Define qué significa que dos items sean iguales para la animación.
    //    Aquí comparamos si el producto y su cantidad son los mismos.
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.productId == rhs.productId &&
               lhs.quantity == rhs.quantity
        // Puedes añadir más comparaciones si son relevantes para detectar un cambio
        // que deba ser animado, por ejemplo:
        // && lhs.price == rhs.price
    }
}
