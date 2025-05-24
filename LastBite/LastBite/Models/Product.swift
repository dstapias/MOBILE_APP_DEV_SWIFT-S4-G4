//
//  Product.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//
//
//  Product.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade ', Identifiable'
struct Product: Codable, Identifiable, Equatable { // ¡Correcto!

    // Implementa el requisito de Identifiable usando product_id
    var id: Int { product_id } // ¡Correcto!

    let product_id: Int
    let name: String
    let detail: String
    let unit_price: Double
    let image: String // URL de la imagen del producto
    let score: Double
    let store_id: Int // ID de la tienda a la que pertenece
    let product_type: String
    
    // Swift puede sintetizar '==' automáticamente para Equatable
    // si todas las propiedades son Equatable (Int, String, Double lo son).
    // No necesitas escribir esto a menos que quieras una lógica de comparación personalizada:
    // static func == (lhs: Product, rhs: Product) -> Bool {
    //     return lhs.product_id == rhs.product_id &&
    //            lhs.name == rhs.name &&
    //            lhs.detail == rhs.detail &&
    //            lhs.unit_price == rhs.unit_price &&
    //            lhs.image == rhs.image &&
    //            lhs.score == rhs.score &&
    //            lhs.store_id == rhs.store_id &&
    //            lhs.product_type == rhs.product_type
    // }
}
