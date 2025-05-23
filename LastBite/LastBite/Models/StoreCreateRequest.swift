//
//  StoreCreateRequest.swift
//  LastBite
//
//  Created by David Santiago on 23/05/25.
//

import Foundation

/// Request body for creating a new Store
struct StoreCreateRequest: Encodable {
    var name: String
    var nit: String
    var address: String
    var longitude: Double
    var latitude: Double
    var logo: String?       // Base64-encoded image or URL
    var opens_at: String    // Format: "HH:mm:ss"
    var closes_at: String   // Format: "HH:mm:ss"

    /// Full initializer
    init(name: String,
         nit: String,
         address: String,
         longitude: Double,
         latitude: Double,
         logo: String? = nil,
         opens_at: String,
         closes_at: String) {
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
