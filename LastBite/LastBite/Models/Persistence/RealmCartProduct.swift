//
//  RealmCartProduct.swift
//  LastBite
//
//  Created by Andrés Romero on 23/04/25.
//

import Foundation
import RealmSwift

/// Realm model que refleja el struct `CartProduct`
class RealmCartProduct: Object {
    /// Clave primaria compuesta: “cartId-productId”
    @Persisted(primaryKey: true) var key: String

    @Persisted var cartId: Int
    @Persisted var productId: Int
    @Persisted var quantity: Int

    // MARK: - Conveniencia

    /// Constructor a partir de tu modelo de dominio
    convenience init(from domain: CartProduct) {
        self.init()
        cartId    = domain.cart_id
        productId = domain.product_id
        quantity  = domain.quantity
        key       = "\(cartId)-\(productId)"
    }
}

extension RealmCartProduct {
    /// Mapea de Realm a dominio
    func toDomain() -> CartProduct {
        CartProduct(
            cart_id: cartId,
            product_id: productId,
            quantity: quantity
        )
    }
}

