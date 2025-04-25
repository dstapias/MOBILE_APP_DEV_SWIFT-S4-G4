//
//  ProductRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 19/04/25.
//

import Foundation

protocol ProductRepository {
    /// Obtiene la lista de productos para una tienda específica.
    func fetchProducts(for storeId: Int) async throws -> [Product]
    
    func createProduct(_ product: ProductCreateRequest) async throws
}
