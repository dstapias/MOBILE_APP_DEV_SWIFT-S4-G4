//
//  RealmCartItem.swift
//  LastBite
//
//  Created by Andrés Romero on 23/04/25.
//

import Foundation

import RealmSwift

/// Realm model correspondiente a `CartItem`
class RealmCartItem: Object {
    @Persisted(primaryKey: true) var productId: Int      // equivale a productId
    @Persisted var cartId: Int                           // para saber a qué carrito pertenece
    @Persisted var name: String = ""                     // nombre del producto
    @Persisted var detail: String = ""                   // detalle o descripción
    @Persisted var quantity: Int = 0                     // cantidad seleccionada
    @Persisted var price: Double = 0.0                   // precio unitario
    @Persisted var imageUrl: String = ""                 // URL de la imagen
    @Persisted var needsSync: Bool = false 
        @Persisted var isDeletedLocally: Bool = false
}

extension RealmCartItem {
    /// Convierte el objeto Realm al struct de dominio `CartItem`
    func toDomain() -> CartItem {
        CartItem(
            productId: productId,
            name: name,
            detail: detail,
            quantity: quantity,
            price: price,
            imageUrl: imageUrl
        )
    }
}
