//
//  CartController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor
class CartController: ObservableObject {

    // MARK: - Published State
    @Published var activeCartId: Int? = nil
    @Published var cartItems: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies (Repositorios)
    private let signInService: SignInUserService
    private let cartRepository: CartRepository
    private let orderRepository: OrderRepository
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor: NetworkMonitor

    // MARK: - Initialization (Recibe Repositorios)
    init(
        signInService: SignInUserService,
        cartRepository: CartRepository,
        orderRepository: OrderRepository,
        networkMonitor: NetworkMonitor
    ) {
        self.signInService = signInService
        self.cartRepository = cartRepository
        self.orderRepository = orderRepository
        self.networkMonitor = networkMonitor
        print("🛒 CartController initialized with Repositories.")
    }

    // MARK: - Data Loading Logic (Async con Repositorio)

    /// Método público para iniciar la carga de datos.
    func loadCartData() {
        Task {
            await fetchActiveCartAndProducts()
        }
    }

    /// Función privada async que realiza la carga real.
    private func fetchActiveCartAndProducts() async {
        guard let userId = signInService.userId else {
            print("❌ CartController: Cannot load cart, user not logged in.")
            self.errorMessage = "Please sign in to view your cart."
            self.cartItems = []
            self.activeCartId = nil
            self.isLoading = false
            return
        }

        guard !isLoading else { return }
        print("⏳ CartController: Loading cart data via Repository for user \(userId)...")
        self.isLoading = true
        self.errorMessage = nil

        do {
            // 1. Obtiene carrito activo usando repositorio
            let cart = try await cartRepository.fetchActiveCart(for: userId)
            self.activeCartId = cart.cart_id // Actualiza ID

            // 2. Obtiene productos detallados usando repositorio
            let detailedProducts = try await cartRepository.fetchDetailedCartProducts(for: cart.cart_id)
            print("✅ CartController: Fetched \(detailedProducts.count) detailed products via Repo.")

            // 3. Mapea a CartItem
            self.cartItems = detailedProducts.map { mapDetailedProductToCartItem($0) }

        } catch let error as ServiceError {
            print("❌ CartController: Failed to load cart data via Repo: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.cartItems = []
            self.activeCartId = nil
        } catch { // Captura cualquier otro error inesperado
             print("❌ CartController: Unexpected error loading cart data via Repo: \(error.localizedDescription)")
             self.errorMessage = "An unexpected error occurred while loading the cart."
             self.cartItems = []
             self.activeCartId = nil
        }
        // Termina la carga independientemente del resultado
        self.isLoading = false
    }

    private func mapDetailedProductToCartItem(_ detailedProduct: DetailedCartProduct) -> CartItem {
        return CartItem(
            productId: detailedProduct.product_id,
            name: detailedProduct.name,
            detail: detailedProduct.detail,
            quantity: detailedProduct.quantity,
            price: detailedProduct.unit_price,
            imageUrl: detailedProduct.image
        )
    }

    // MARK: - Cart Modification Logic (Async con Repositorio)

    /// Método público (síncrono) que lanza la tarea para eliminar item.
    func removeItemFromCart(productId: Int) {
        Task {
            await performRemoveItem(productId: productId)
        }
    }

    /// Helper async privado que realiza la eliminación.
    private func performRemoveItem(productId: Int) async {
        guard let cartId = activeCartId else {
            errorMessage = "Cannot modify cart (no active cart found)."
            return
        }
        guard !isLoading else { return }

        print("⏳ CartController: Attempting to remove product \(productId) via Repository...")
        self.errorMessage = nil

        do {
            // Llama al REPOSITORIO
            try await cartRepository.removeProductFromCart(cartId: cartId, productId: productId)
            print("✅ CartController: Product \(productId) removed via Repo. Refreshing cart...")
            // Refresca los datos después de la modificación exitosa
            await fetchActiveCartAndProducts() // Vuelve a cargar todo

        } catch let error as ServiceError {
            print("❌ CartController: Failed to remove product \(productId) via Repo: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false // Detiene carga en error
        } catch {
             print("❌ CartController: Unexpected error removing product \(productId) via Repo: \(error.localizedDescription)")
             self.errorMessage = "Failed to remove item."
             self.isLoading = false
        }
    }

     /// Método público (síncrono) que lanza la tarea para actualizar cantidad.
    func updateCartQuantity(productId: Int, newQuantity: Int) {
         Task {
             await performUpdateQuantity(productId: productId, newQuantity: newQuantity)
         }
     }

    /// Helper async privado que realiza la actualización de cantidad.
    private func performUpdateQuantity(productId: Int, newQuantity: Int) async {
        guard let cartId = activeCartId else {
             errorMessage = "Cannot modify cart (no active cart found)."
             return
        }
        // Llama a eliminar si la cantidad es 0 o menos
        guard newQuantity > 0 else {
             print("ℹ️ Quantity is zero or less, removing item instead.")
             await performRemoveItem(productId: productId)
             return
         }
        guard !isLoading else { return }

        print("⏳ CartController: Attempting to update product \(productId) to quantity \(newQuantity) via Repository...")
        self.errorMessage = nil

         do {
             // Llama al REPOSITORIO
             try await cartRepository.updateProductQuantity(cartId: cartId, productId: productId, quantity: newQuantity)
             print("✅ CartController: Quantity for product \(productId) updated via Repo. Refreshing cart...")
             // Refresca los datos
             await fetchActiveCartAndProducts()
         } catch let error as ServiceError {
             print("❌ CartController: Failed to update quantity for product \(productId) via Repo: \(error.localizedDescription)")
             self.errorMessage = error.localizedDescription
             self.isLoading = false
         } catch {
             print("❌ CartController: Unexpected error updating quantity for product \(productId) via Repo: \(error.localizedDescription)")
             self.errorMessage = "Failed to update quantity."
             self.isLoading = false
         }
    }

    func prepareCheckoutController() -> CheckoutController? {
         guard let cartId = self.activeCartId, !self.cartItems.isEmpty else {
             print("❌ CartController: Cannot proceed to checkout. Cart is empty or inactive.")
             self.errorMessage = "Your cart is empty or unavailable for checkout."
             return nil
         }
         // Crea CheckoutController inyectándole los repositorios que necesita
         return CheckoutController(
             cartItems: self.cartItems,
             cartId: cartId,
             signInService: self.signInService, // Pasa servicio de usuario
             orderRepository: self.orderRepository, // Pasa repo de órdenes
             cartRepository: self.cartRepository, networkMonitor: self.networkMonitor
         )
    }
}
