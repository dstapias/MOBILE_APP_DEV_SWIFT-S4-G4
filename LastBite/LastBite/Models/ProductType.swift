//
//  ProductType.swift
//  LastBite
//
//  Created by David Santiago on 25/04/25.
//

import Foundation

enum ProductType: String, CaseIterable, Identifiable {
    case product = "PRODUCT"
    case subscription = "SUBSCRIPTION"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .product: return "Producto"
        case .subscription: return "Subscripción"
        }
    }
}
