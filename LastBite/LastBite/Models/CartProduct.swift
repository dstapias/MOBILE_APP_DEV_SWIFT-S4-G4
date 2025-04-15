//
//  CartProduct.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct CartProduct: Codable {
    let cart_id: Int
    let product_id: Int
    let quantity: Int
}
