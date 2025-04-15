//
//  CheckoutController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine // Necesario para ObservableObject

// Asumiendo que tienes estos servicios (pueden seguir siendo singletons o inyectados)
// class OrderService { static let shared = OrderService(); /* ... métodos ... */ }
// class CartService { static let shared = CartService(); /* ... métodos ... */ }
// class SignInUserService: ObservableObject { @Published var userId: Int? = 123 }


class CheckoutController: ObservableObject {

    // MARK: - Published Properties (Estado para la Vista)
    @Published var deliveryMethod: String = "In-store Pickup" // Puedes inicializar o configurar luego
    @Published var paymentMethod: String = "Cash"         // Puedes inicializar o configurar luego
    @Published var totalCost: Double = 0.0
    @Published var showOrderAccepted: Bool = false
    @Published var createdOrderId: Int? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies (Inyectadas)
    private let cartItems: [CartItem]
    private let cartId: Int
    private let signInService: SignInUserService
    private let orderService: OrderService // Usaremos instancias inyectadas
    private let cartService: CartService   // Usaremos instancias inyectadas

    // MARK: - Initialization
    init(
        cartItems: [CartItem],
        cartId: Int,
        signInService: SignInUserService,
        orderService: OrderService = OrderService.shared, // Puedes usar singletons aquí o pasar instancias específicas
        cartService: CartService = CartService.shared
    ) {
        self.cartItems = cartItems
        self.cartId = cartId
        self.signInService = signInService
        self.orderService = orderService
        self.cartService = cartService
        self.calculateTotalCost() // Calcular al iniciar
        print("🛒 CheckoutController initialized for cart ID: \(cartId)")
    }

    // MARK: - Private Methods
    private func calculateTotalCost() {
        self.totalCost = cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        print("💰 Total cost calculated: \(self.totalCost)")
    }

    // MARK: - Public Actions (Llamados desde la Vista)

    /// Inicia el proceso de checkout completo.
    func confirmCheckout() {
        print("▶️ Controller: confirmCheckout action initiated")
        guard let userId = signInService.userId else {
            print("❌ Controller: User ID not found in SignInService")
            self.errorMessage = "User is not logged in. Please sign in." // Mensaje más descriptivo
            return
        }

        // Reiniciar estado de error/carga
        self.errorMessage = nil
        self.isLoading = true
        print("⏳ Controller: Starting checkout process for cart ID: \(cartId), user ID: \(userId), total: \(totalCost)")

        // 1. Crear Pedido
        orderService.createOrder(cartId: cartId, userId: userId, totalPrice: totalCost) { [weak self] createResult in
            guard let self = self else { return }

            switch createResult {
            case .success(let orderId):
                print("✅ Controller: Order created with ID \(orderId). Proceeding to update order...")
                // 2. Actualizar Pedido (si la creación fue exitosa)
                self.updateOrder(orderId: orderId, userId: userId) // Pasamos userId por si se necesita en updateCartStatus

            case .failure(let error):
                print("❌ Controller: Failed to create order: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create order: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Actualiza el pedido y, si tiene éxito, actualiza el carrito.
    private func updateOrder(orderId: Int, userId: Int) {
        print("⏳ Controller: Updating order \(orderId)...")
        orderService.updateOrder(orderId: orderId, status: "BILLED", totalPrice: totalCost) { [weak self] updateOrderResult in
            guard let self = self else { return }

            switch updateOrderResult {
            case .success:
                print("✅ Controller: Order \(orderId) updated successfully. Proceeding to update cart...")
                // 3. Actualizar Carrito (si la actualización del pedido fue exitosa)
                self.updateCartStatus(orderId: orderId, userId: userId) // Pasamos orderId para el final

            case .failure(let error):
                print("❌ Controller: Failed to update order \(orderId): \(error.localizedDescription)")
                // Podrías intentar revertir o manejar este error de forma más específica
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to update order details: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Actualiza el estado del carrito. Es el último paso.
    private func updateCartStatus(orderId: Int, userId: Int) {
         print("⏳ Controller: Updating cart \(cartId) status...")
        cartService.updateCartStatus(cartId: cartId, status: "BILLED", userId: userId) { [weak self] updateCartResult in
            guard let self = self else { return }

            // Asegurarse de actualizar la UI en el hilo principal
            DispatchQueue.main.async {
                self.isLoading = false // Termina la carga independientemente del resultado final

                switch updateCartResult {
                case .success:
                    print("✅ Controller: Cart \(self.cartId) status updated. Checkout complete!")
                    self.createdOrderId = orderId
                    self.showOrderAccepted = true // Dispara la navegación en la vista

                case .failure(let error):
                    print("❌ Controller: Failed to update cart \(self.cartId) status: \(error.localizedDescription)")
                    // Error crítico, el pedido se creó/actualizó pero el carrito no.
                    self.errorMessage = "Checkout partially failed: Could not update cart status. Please contact support. Order ID: \(orderId)"
                }
            }
        }
    }
}

