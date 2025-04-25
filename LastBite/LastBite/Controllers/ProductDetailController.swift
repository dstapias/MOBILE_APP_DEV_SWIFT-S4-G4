//
//  ProductDetailController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

@MainActor
class ProductDetailController: ObservableObject {

    @Published var quantity: Int = 1
    @Published var isLoading: Bool = false
    @Published var successMessage: String? = nil
    @Published var errorMessage: String? = nil

    let product: Product

    private let signInService: SignInUserService
    private let cartRepository: CartRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        product: Product,
        signInService: SignInUserService = SignInUserService.shared,
        cartRepository: CartRepository
    ) {
        self.product = product
        self.signInService = signInService
        self.cartRepository = cartRepository
        print("📦 ProductDetailController initialized with Repository for product: \(product.name)")

        $quantity
            .map { max(1, $0) }
            .assign(to: &$quantity)
    }

    func addToCart() async { // Marcado como async
        guard let userId = signInService.userId else {
            errorMessage = "Please sign in to add items to your cart."
            successMessage = nil
            print("❌ Cannot add to cart, user not logged in.")
            return
        }
        guard !isLoading else { return } // Evita múltiples taps

        print("🛒 Attempting to add \(quantity) x \(product.name) (ID: \(product.id)) to cart via Repository...")

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let cart = try await cartRepository.fetchActiveCart(for: userId)

            try await cartRepository.addProductToCart(cartId: cart.id, product: product, quantity: quantity)

            // Éxito
            print("✅ Product \(product.id) added/updated in cart \(cart.id) via Repo. Quantity: \(quantity)")
            successMessage = "\(quantity) x \(product.name) added!"
             // Limpia el mensaje después de un tiempo
             Task {
                 try? await Task.sleep(nanoseconds: 2_500_000_000) // Espera 2.5 segundos
                 // Verifica si el mensaje sigue siendo el mismo antes de limpiarlo
                 if self.successMessage == "\(quantity) x \(self.product.name) added!" {
                    self.successMessage = nil
                 }
             }

        } catch let error as ServiceError { // Captura errores específicos
            print("❌ Failed to add product to cart via Repo: \(error.localizedDescription)")
            // Muestra un mensaje de error más específico si es posible
            self.errorMessage = "Failed to add item: \(error.localizedDescription)"
        } catch { // Captura otros errores inesperados
             print("❌ Unexpected error adding product to cart via Repo: \(error.localizedDescription)")
             self.errorMessage = "An unexpected error occurred while adding the item."
        }

        // Termina la carga independientemente del resultado
        isLoading = false
    }

}
