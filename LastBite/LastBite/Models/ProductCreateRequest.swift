//
//  ProductCreateModel.swift
//  LastBite
//
//  Created by David Santiago on 23/04/25.
//

import Foundation

struct ProductCreateRequest: Encodable {
    let name: String
    let detail: String
    let image: String //URL
    let product_type: String
    let score: Double
    let store_id: Int
    let unit_price: Double
}
