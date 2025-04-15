//
//  CartController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine // ¡Importante para ObservableObject!

// Asumiendo que estos servicios existen y funcionan como en tu código original
// class CartService { static let shared = CartService(); /* ... */ }
// class CartProductService { static let shared = CartProductService(); /* ... */ }
// class SignInUserService: ObservableObject { @Published var userId: Int? = 123 } // Ejemplo
// struct CartItem: Identifiable { /* ... productId: Int ... quantity: var Int ... */ }

// 1. Hacerlo ObservableObject
class CartController: ObservableObject {

    // 2. Publicar el estado para que la vista reaccione
    @Published var activeCartId: Int? = nil
    @Published var cartItems: [CartItem] = []
    @Published var isLoading: Bool = false // Para indicadores de carga
    @Published var errorMessage: String? = nil // Para mostrar errores

    // 3. Dependencias (Inyectadas para mejor testabilidad y flexibilidad)
    private let signInService: SignInUserService
    private let cartService: CartService
    private let cartProductService: CartProductService

    // 4. Inicializador para recibir dependencias
    init(
        signInService: SignInUserService,
        cartService: CartService = CartService.shared, // Puedes seguir usando singletons aquí si prefieres
        cartProductService: CartProductService = CartProductService.shared
    ) {
        self.signInService = signInService
        self.cartService = cartService
        self.cartProductService = cartProductService
        print("🛒 CartController initialized.")
    }

    // MARK: - Data Loading Logic

    /// Método principal para cargar datos cuando la vista aparece.
    func loadCartData() {
        guard let userId = signInService.userId else {
            print("❌ CartController: Cannot load cart, user not logged in.")
            self.errorMessage = "Please sign in to view your cart."
            // Asegurarse que el estado refleje "vacío" si no hay usuario
            self.cartItems = []
            self.activeCartId = nil
            self.isLoading = false // No estamos cargando si no hay usuario
            return
        }

        print("⏳ CartController: Loading cart data for user \(userId)...")
        DispatchQueue.main.async { // Asegurar que los cambios iniciales de UI estén en main thread
            self.isLoading = true
            self.errorMessage = nil
        }

        // Llama a la función interna que busca el ID del carrito
        fetchActiveCartInternal(for: userId)
    }

    /// Paso 1 (Interno): Obtiene el ID del carrito activo.
    private func fetchActiveCartInternal(for userId: Int) {
        cartService.fetchActiveCart(for: userId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cart): // Asumiendo que 'cart' tiene 'cart_id'
                // No necesitas DispatchQueue.main.async aquí porque el siguiente paso lo hará
                print("✅ CartController: Found active cart ID:", cart.cart_id)
                self.activeCartId = cart.cart_id // Actualiza el ID publicado
                // Paso 2: Cargar productos usando el ID obtenido
                self.fetchCartProductsInternal(cartId: cart.cart_id)

            case .failure(let error):
                print("❌ CartController: Failed to find active cart:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.activeCartId = nil
                    self.cartItems = [] // Limpiar items si falla encontrar carrito
                    self.isLoading = false
                    self.errorMessage = "Could not find your active cart." // Mensaje para el usuario
                }
            }
        }
    }

    /// Paso 2 (Interno): Carga los productos detallados del carrito activo.
    /// Se llama después de obtener `activeCartId`.
    private func fetchCartProductsInternal(cartId: Int) {
        print("⏳ CartController: Fetching products for cart ID \(cartId)...")
        // isLoading ya debería ser true

        cartProductService.fetchDetailedCartProducts(for: cartId) { [weak self] result in
            guard let self = self else { return }

            // Siempre actualiza la UI en el hilo principal
            DispatchQueue.main.async {
                 self.isLoading = false // Termina la carga aquí

                switch result {
                case .success(let cartProducts): // 'cartProducts' es tu array de datos crudos
                    // Mapea tus datos crudos al modelo `CartItem` que usa la UI
                    self.cartItems = cartProducts.map { cartProductData in
                        CartItem(
                            // Asumiendo que CartItem tiene un 'id' único para Identifiable
                            // Si no, puedes necesitar generar uno o ajustar el ForEach en la vista.
                            // id: UUID().uuidString, // Ejemplo si necesitas un ID y no viene del backend
                            productId: cartProductData.product_id,
                            name: cartProductData.name,
                            detail: cartProductData.detail,
                            quantity: cartProductData.quantity, // Asegúrate que CartItem.quantity sea 'var'
                            price: cartProductData.unit_price,
                            imageUrl: cartProductData.image
                        )
                    }
                    print("✅ CartController: Fetched \(self.cartItems.count) products.")
                    self.errorMessage = nil // Limpiar errores previos si la carga fue exitosa

                case .failure(let error):
                    print("❌ CartController: Failed to fetch cart products:", error.localizedDescription)
                    self.cartItems = [] // Limpiar items en caso de error
                    self.errorMessage = "Failed to load cart items."
                }
            }
        }
    }

    // MARK: - Cart Modification Logic

    /// Elimina un producto del carrito. Ya no necesita `completion`.
    func removeItemFromCart(productId: Int) {
        guard let cartId = activeCartId else {
            print("❌ CartController: Cannot remove item, no active cart ID.")
            self.errorMessage = "Cannot modify cart (no active cart found)."
            return
        }

        print("⏳ CartController: Attempting to remove product \(productId) from cart \(cartId)...")
        DispatchQueue.main.async { // Asegurar cambios de UI en main thread
             self.isLoading = true // Podrías tener un estado de carga más granular
             self.errorMessage = nil
        }


        cartProductService.removeProductFromCart(cartID: cartId, productID: productId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                 print("✅ CartController: Product \(productId) removed successfully via service. Refreshing cart...")
                 // Refresca los datos para asegurar consistencia después de la eliminación
                 // Llama a la función interna que recarga los productos
                 // Asegurarse que las actualizaciones de UI (isLoading=false) se hagan dentro de fetchCartProductsInternal
                 self.fetchCartProductsInternal(cartId: cartId)

            case .failure(let error):
                 print("❌ CartController: Failed to remove product \(productId):", error.localizedDescription)
                 DispatchQueue.main.async {
                     self.isLoading = false // Terminar carga en caso de error
                     self.errorMessage = "Failed to remove item."
                 }
            }
        }
    }

    /// Actualiza la cantidad. Ya no necesita `completion`.
    func updateCartQuantity(productId: Int, newQuantity: Int) {
        guard let cartId = activeCartId else {
            print("❌ CartController: Cannot update quantity, no active cart ID.")
            self.errorMessage = "Cannot modify cart (no active cart found)."
            return
        }
        guard newQuantity > 0 else { return } // O llama a remove si es 0

        print("⏳ CartController: Attempting to update product \(productId) quantity to \(newQuantity)...")
         DispatchQueue.main.async {
             self.isLoading = true
             self.errorMessage = nil
         }


        cartProductService.updateProductQuantity(cartID: cartId, productID: productId, quantity: newQuantity) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                 print("✅ CartController: Quantity for product \(productId) updated successfully via service. Refreshing cart...")
                 // Refresca los datos para asegurar consistencia
                 // Las actualizaciones de UI (isLoading=false) se harán dentro de fetchCartProductsInternal
                 self.fetchCartProductsInternal(cartId: cartId)

            case .failure(let error):
                 print("❌ CartController: Failed to update quantity for product \(productId):", error.localizedDescription)
                 DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to update quantity."
                 }
            }
        }
    }

    // MARK: - Navigation Helper

    /// Prepara y devuelve un controlador para la pantalla de Checkout.
    func prepareCheckoutController() -> CheckoutController? {
        // Usa las propiedades @Published directamente
        guard let cartId = self.activeCartId, !self.cartItems.isEmpty else {
             print("❌ CartController: Cannot proceed to checkout. Cart is empty or inactive.")
             DispatchQueue.main.async { // Asegúrate que el mensaje de error se muestre
                 self.errorMessage = "Your cart is empty or unavailable for checkout."
             }
            return nil
        }

        // Crea la instancia de CheckoutController inyectando lo necesario
        return CheckoutController(
            cartItems: self.cartItems, // Pasa los items actuales
            cartId: cartId,            // Pasa el ID activo
            signInService: self.signInService // Pasa la dependencia
            // Si CheckoutController necesita otros servicios, considéralo aquí
        )
    }
}
