//
//  Area.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//
import Foundation

struct Area: Codable, Identifiable, Equatable {

    // Define 'id' usando 'area_id'
    var id: Int { area_id }

    let area_id: Int
    let area_name: String
    // Probablemente también tengas 'zone_id: Int' aquí si lo necesitas

    // Swift genera '==' automáticamente para Equatable
}
