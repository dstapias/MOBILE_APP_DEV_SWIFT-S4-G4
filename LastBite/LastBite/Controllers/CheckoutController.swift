//
//  CheckoutController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor
class CheckoutController: ObservableObject {

    // MARK: - Published Properties (Estado para la Vista)
    @Published var deliveryMethod: String = "In-store Pickup"
    @Published var paymentMethod: String = "Cash"
    @Published var totalCost: Double = 0.0 // Se calcula al inicio
    @Published var showOrderAccepted: Bool = false
    @Published var createdOrderId: Int? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Properties (Datos necesarios)
    private let cartItems: [CartItem]
    private let cartId: Int

    // --- CAMBIO 1: Dependencias -> Repositorios ---
    private let signInService: SignInUserService
    private let orderRepository: OrderRepository // <- USA OrderRepository
    private let cartRepository: CartRepository  // <- USA CartRepository
    // Ya no necesita OrderService ni CartService directamente

    // --- CAMBIO 2: Init -> Recibe Repositorios ---
    init(
        cartItems: [CartItem],
        cartId: Int,
        signInService: SignInUserService,
        orderRepository: OrderRepository, // <- Recibe OrderRepository
        cartRepository: CartRepository   // <- Recibe CartRepository
    ) {
        self.cartItems = cartItems
        self.cartId = cartId
        self.signInService = signInService
        self.orderRepository = orderRepository // <- Guarda OrderRepository
        self.cartRepository = cartRepository   // <- Guarda CartRepository
        print("🛒 CheckoutController initialized with Repositories for cart ID: \(cartId)")
        // Calcula costo total al inicio
        self.calculateTotalCost()
    }

    // MARK: - Private Methods (Cálculo - Sin cambios)
    private func calculateTotalCost() {
        self.totalCost = cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        print("💰 Total cost calculated: \(self.totalCost)")
    }

    // MARK: - Public Actions (Refactorizado a Async)

    /// Inicia y ejecuta todo el proceso de checkout de forma asíncrona.
    func confirmCheckout() async { // Marcado como async
        print("▶️ Controller: confirmCheckout action initiated")
        guard let userId = signInService.userId else {
            errorMessage = "User is not logged in. Please sign in."
            return
        }
        guard !isLoading else { return } // Evita doble ejecución

        // Reiniciar estado
        isLoading = true
        errorMessage = nil
        createdOrderId = nil
        showOrderAccepted = false
        print("⏳ Controller: Starting checkout process via Repositories...")

        do {
            // --- Llama a los repositorios secuencialmente usando try await ---
            // 1. Crear Orden (obtiene ID)
            print("   Attempting to create order...")
            let newOrderId = try await orderRepository.createOrder(
                cartId: cartId, userId: userId, totalPrice: totalCost
            )
            self.createdOrderId = newOrderId // Guarda el ID por si lo necesitas
            print("   ✅ Order created with ID: \(newOrderId)")

            // 2. Actualizar Orden a "BILLED"
            print("   Attempting to update order status...")
            try await orderRepository.updateOrder(
                orderId: newOrderId, status: "BILLED", totalPrice: totalCost
            )
            print("   ✅ Order \(newOrderId) updated.")

            // 3. Actualizar Estado del Carrito a "BILLED"
            print("   Attempting to update cart status...")
            // Asegúrate que updateCartStatus en CartRepository/Service no necesite userId si no es parte de la URL/body
            try await cartRepository.updateCartStatus(
                cartId: cartId, status: "BILLED", userId: userId
            )
            print("   ✅ Cart \(cartId) status updated.")

            // --- Éxito Total ---
            print("✅ Controller: Checkout complete!")
            showOrderAccepted = true // Dispara la navegación en la vista

        } catch let error as ServiceError { // Captura errores específicos
            print("❌ Controller: Checkout failed: \(error.localizedDescription)")
            errorMessage = "Checkout failed: \(error.localizedDescription)"
            // Considera si necesitas lógica de rollback aquí si un paso falla después de otro exitoso
        } catch { // Otros errores
            print("❌ Controller: Unexpected checkout error: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred during checkout."
        }

        // Termina la carga independientemente del resultado
        isLoading = false
    }

    // 4. Los métodos privados updateOrder y updateCartStatus ya no son necesarios
    //    porque su lógica está ahora dentro de confirmCheckout.
}
