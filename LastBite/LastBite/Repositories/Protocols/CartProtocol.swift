//
//  CartProtocol.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation

// Protocolo para TODAS las operaciones relacionadas con el Carrito y sus Productos
protocol CartRepository {
    // --- Operaciones del Carrito ---
    func fetchActiveCart(for userId: Int) async throws -> Cart
    func updateCartStatus(cartId: Int, status: String, userId: Int) async throws

    // --- Operaciones de Productos en Carrito ---
    func fetchCartProducts(for cartId: Int) async throws -> [CartProduct]
    func fetchDetailedCartProducts(for cartId: Int) async throws -> [DetailedCartProduct]

    // Acciones de modificación
    func addProductToCart(cartId: Int, productId: Int, quantity: Int) async throws
    func updateProductQuantity(cartId: Int, productId: Int, quantity: Int) async throws
    func removeProductFromCart(cartId: Int, productId: Int) async throws
}
