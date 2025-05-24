//
//  StoreUpdateRequest.swift
//  LastBite
//
//  Created by Andrés Romero on 13/05/25.
//

import Foundation

struct StoreUpdateRequest: Encodable { // O Codable si también lo decodificas en algún punto
    var name: String?       // Cambiado a opcional
    var nit: String?        // Cambiado a opcional
    var address: String?    // Cambiado a opcional
    var longitude: Double?  // Cambiado a opcional
    var latitude: Double?   // Cambiado a opcional
    var logo: String?       // Ya era opcional
    var opens_at: String?   // Cambiado a opcional
    var closes_at: String?  // Cambiado a opcional
    
    // Inicializador para facilitar la creación (opcional pero útil)
    init(name: String? = nil,
         nit: String? = nil,
         address: String? = nil,
         longitude: Double? = nil,
         latitude: Double? = nil,
         logo: String? = nil,
         opens_at: String? = nil,
         closes_at: String? = nil) {
        self.name = name
        self.nit = nit
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
        self.logo = logo
        self.opens_at = opens_at
        self.closes_at = closes_at
    }
}
