//
//  Store.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct Store: Codable {
    let store_id: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let logo: String
    let nit: String
}
