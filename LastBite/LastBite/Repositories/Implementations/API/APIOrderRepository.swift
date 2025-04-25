//
//  APIOrderRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation

// Implementación concreta que usa OrderService
class APIOrderRepository: OrderRepository {
    private let orderService: OrderService // Dependencia del servicio

    // Inyección de dependencias
    init(orderService: OrderService = OrderService.shared) {
        self.orderService = orderService
        print("📦 APIOrderRepository initialized.")
    }

    // Implementación de los métodos del protocolo

    func fetchNotReceivedOrders(userId: Int) async throws -> [Order] {
        // Llama directamente al método async del servicio
        try await orderService.fetchNotReceivedOrdersForUserAsync(userId: userId)
    }

    func markOrderAsReceived(orderId: Int) async throws {
        // Llama directamente al método async del servicio
        try await orderService.receiveOrderAsync(orderId: orderId)
    }
    
    func createOrder(cartId: Int, userId: Int, totalPrice: Double) async throws -> Int {
            // Llama al método async del servicio
            // Asume que createOrderAsync devuelve el Int del ID o lanza error
            try await orderService.createOrderAsync(cartId: cartId, userId: userId, totalPrice: totalPrice)
        }

        func updateOrder(orderId: Int, status: String, totalPrice: Double) async throws {
            // Llama al método async del servicio
            try await orderService.updateOrderAsync(orderId: orderId, status: status, totalPrice: totalPrice)
        }
}
