//
//  Zone.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// Añade ', Identifiable, Equatable'
struct Zone: Codable, Identifiable, Equatable {

    // Define 'id' usando 'zone_id'
    var id: Int { zone_id }

    let zone_id: Int
    let zone_name: String

    // No necesitas escribir 'static func ==', Swift lo genera por ti
    // para Equatable porque es un struct con propiedades Equatable.
}
