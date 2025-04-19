//
//  APICartRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation

// Implementación que usa CartService y CartProductService
class APICartRepository: CartRepository {

    // Dependencias de los servicios refactorizados
    private let cartService: CartService
    private let cartProductService: CartProductService

    // Inyección de dependencias
    init(
        cartService: CartService = CartService.shared,
        cartProductService: CartProductService = CartProductService.shared
    ) {
        self.cartService = cartService
        self.cartProductService = cartProductService
        print("🛒 APICartRepository initialized.")
    }

    // MARK: - Cart Methods Implementation
    func fetchActiveCart(for userId: Int) async throws -> Cart {
        try await cartService.fetchActiveCartAsync(for: userId)
    }

    func updateCartStatus(cartId: Int, status: String, userId: Int) async throws {
        try await cartService.updateCartStatusAsync(cartId: cartId, status: status, userId: userId)
    }

    // MARK: - CartProduct Methods Implementation
    func fetchCartProducts(for cartId: Int) async throws -> [CartProduct] {
        try await cartProductService.fetchCartProductsAsync(for: cartId)
    }

    func fetchDetailedCartProducts(for cartId: Int) async throws -> [DetailedCartProduct] {
         try await cartProductService.fetchDetailedCartProductsAsync(for: cartId)
    }

    func addProductToCart(cartId: Int, productId: Int, quantity: Int) async throws {
        try await cartProductService.addProductToCartAsync(cartID: cartId, productID: productId, quantity: quantity)
    }

    func updateProductQuantity(cartId: Int, productId: Int, quantity: Int) async throws {
        try await cartProductService.updateProductQuantityAsync(cartID: cartId, productID: productId, quantity: quantity)
    }

    func removeProductFromCart(cartId: Int, productId: Int) async throws {
        try await cartProductService.removeProductFromCartAsync(cartID: cartId, productID: productId)
    }
}
