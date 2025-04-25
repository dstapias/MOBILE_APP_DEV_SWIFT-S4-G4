//
//  Tag.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct Tag: Codable {
    let product_id: Int
    let product_tag_id: Int
    let value: String // ✅ Stores tag value (e.g., "Organic", "Gluten-Free")
}
