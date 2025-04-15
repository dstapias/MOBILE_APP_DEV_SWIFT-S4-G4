//
//  ProductDetailController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

class ProductDetailController: ObservableObject {

    // MARK: - Published State
    @Published var quantity: Int = 1
    @Published var isLoading: Bool = false // Para la acción de añadir al carrito
    @Published var successMessage: String? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Properties
    let product: Product // El producto que estamos mostrando

    // MARK: - Dependencies
    private let signInService: SignInUserService
    private let cartService: CartService
    private let cartProductService: CartProductService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        product: Product,
        signInService: SignInUserService = SignInUserService.shared,
        cartService: CartService = CartService.shared,
        cartProductService: CartProductService = CartProductService.shared
    ) {
        self.product = product
        self.signInService = signInService
        self.cartService = cartService
        self.cartProductService = cartProductService
        print("📦 ProductDetailController initialized for product: \(product.name) (ID: \(product.id))")

        // Podrías añadir lógica para limitar quantity si el producto tiene stock, etc.
        $quantity
            .map { max(1, $0) } // Asegura que la cantidad sea al menos 1
            .assign(to: &$quantity)
    }

    // MARK: - Actions
    func addToCart() {
        guard let userId = signInService.userId else {
            errorMessage = "Please sign in to add items to your cart."
            successMessage = nil
            print("❌ Cannot add to cart, user not logged in.")
            return
        }

        guard !isLoading else { return } // Evita múltiples taps

        print("🛒 Attempting to add \(quantity) x \(product.name) (ID: \(product.id)) to cart for user \(userId)...")

        isLoading = true
        errorMessage = nil
        successMessage = nil

        // 1. Obtener Carrito Activo
        cartService.fetchActiveCart(for: userId) { [weak self] cartResult in
            guard let self = self else { return }

            switch cartResult {
            case .success(let cart):
                // 2. Añadir Producto al Carrito (o actualizar cantidad)
                // Nota: La lógica exacta aquí depende de tu backend/servicio.
                // Esto asume que addProductToCart maneja la lógica de
                // añadir/actualizar cantidad si el producto ya existe.
                self.addProductToSpecificCart(cartId: cart.cart_id, productId: self.product.id, quantityToAdd: self.quantity)

            case .failure(let error):
                 print("❌ Failed to find active cart: \(error.localizedDescription)")
                 DispatchQueue.main.async {
                     self.isLoading = false
                     self.errorMessage = "Could not find your active cart."
                 }
            }
        }
    }

    private func addProductToSpecificCart(cartId: Int, productId: Int, quantityToAdd: Int) {
        // NOTA IMPORTANTE: Tu servicio `addProductToCart` actual probablemente solo añade 1.
        // Necesitarás un servicio que añada una CANTIDAD específica o que actualice
        // la cantidad si el producto ya está. Aquí simulamos llamando al servicio existente
        // repetidamente o asumiendo que tienes un servicio `updateProductQuantity` o similar.
        // Por simplicidad, llamaremos al servicio que ya tenías, pero esto puede no ser
        // lo correcto para añadir MÁS de 1 o actualizar. ¡DEBES AJUSTAR ESTO!

        // *** Inicio de Lógica de Ejemplo (¡AJUSTAR A TU SERVICIO REAL!) ***
        // Esto es solo un placeholder. Necesitas llamar al servicio correcto.
        // Si tu servicio solo añade 1, necesitarías llamarlo 'quantityToAdd' veces
        // o mejor, tener un endpoint/servicio que acepte cantidad.
        cartProductService.addProductToCart(cartID: cartId, productID: productId) { [weak self] addResult in
             guard let self = self else { return }
             DispatchQueue.main.async {
                 self.isLoading = false // Termina la carga
                 switch addResult {
                 case .success:
                     print("✅ Product \(productId) added/updated in cart \(cartId). Quantity: \(quantityToAdd)")
                     self.successMessage = "\(quantityToAdd) x \(self.product.name) added!"
                      // Limpia el mensaje después de un tiempo
                     DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                         if self.successMessage != nil { self.successMessage = nil }
                     }
                 case .failure(let error):
                     print("❌ Failed to add product \(productId) to cart \(cartId): \(error.localizedDescription)")
                     self.errorMessage = "Failed to add item: \(error.localizedDescription)"
                 }
            }
        }
         // *** Fin de Lógica de Ejemplo ***
    }

    // Helper para incrementar/decrementar cantidad (opcional, Stepper lo hace)
    // func incrementQuantity() { quantity += 1 }
    // func decrementQuantity() { quantity = max(1, quantity - 1) }
}
