//
//  DetailedCartProduct.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade Identifiable, Equatable
struct DetailedCartProduct: Codable, Identifiable, Equatable {
    // Define 'id' para Identifiable usando 'product_id'
    var id: Int { product_id }

    let product_id: Int
    let name: String
    let detail: String // ¿Debería ser opcional? detail: String?
    let quantity: Int
    let unit_price: Double
    let image: String

    // Swift genera '==' para Equatable automáticamente
}
