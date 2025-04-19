//
//  CartProduct.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade Equatable
struct CartProduct: Codable, Equatable {
    let cart_id: Int
    let product_id: Int
    let quantity: Int

    // Swift genera '==' para Equatable automáticamente
    // Añadir Identifiable si se necesita usar en ForEach directamente:
    // var id: String { "\(cart_id)-\(product_id)" }
}
