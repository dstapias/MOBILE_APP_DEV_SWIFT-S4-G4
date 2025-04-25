//
//  APIProductRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 19/04/25.
//

import Foundation

class APIProductRepository: ProductRepository {
    private let productService: ProductService // Dependencia del servicio async

    init(productService: ProductService = ProductService.shared) {
        self.productService = productService
        print("📦 APIProductRepository initialized.")
    }

    func fetchProducts(for storeId: Int) async throws -> [Product] {
        // Llama directamente al método async del servicio
        try await productService.fetchProductsAsync(for: storeId)
    }
    
    func createProduct(_ product: ProductCreateRequest) async throws {
            try await productService.createProduct(product)
    }

}
