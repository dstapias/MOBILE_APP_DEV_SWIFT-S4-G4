//
//  Product.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade ', Identifiable'
struct Product: Codable, Identifiable, Equatable {

    // Implementa el requisito de Identifiable usando product_id
    var id: Int { product_id }

    let product_id: Int
    let name: String
    let detail: String
    let unit_price: Double
    let image: String
    let score: Double
    let store_id: Int
    let product_type: String
}
