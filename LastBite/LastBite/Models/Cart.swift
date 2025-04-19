//
//  Cart.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade Identifiable, Equatable
struct Cart: Codable, Identifiable, Equatable {
    // Define 'id' para Identifiable
    var id: Int { cart_id }

    let cart_id: Int
    let creation_date: String // Considera usar Date si es posible con un DateFormatter
    let status: String
    let status_date: String // Considera usar Date
    let user_id: Int

    // Swift genera '==' para Equatable automáticamente
}
