//
//  OrderRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation

// Protocolo para operaciones relacionadas con Órdenes
protocol OrderRepository {
    /// Obtiene las órdenes no marcadas como recibidas para un usuario.
    func fetchNotReceivedOrders(userId: Int) async throws -> [Order]

    /// Marca una orden específica como recibida.
    func markOrderAsReceived(orderId: Int) async throws // Cambié el nombre para claridad
    
    /// Crea una nueva orden.
        /// - Returns: El ID de la orden creada.
        func createOrder(cartId: Int, userId: Int, totalPrice: Double) async throws -> Int

        /// Actualiza el estado y precio de una orden existente.
        func updateOrder(orderId: Int, status: String, totalPrice: Double) async throws
}
