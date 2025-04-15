//
//  DetailedCartProduct.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct DetailedCartProduct: Codable {
      let product_id: Int
      let name: String
      let detail: String
      let quantity: Int
      let unit_price: Double
      let image: String
  }
