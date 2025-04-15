//
//  ProductController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

class ProductController: ObservableObject {

    // MARK: - Published State
    @Published var products: [Product] = [] // Lista original de productos
    @Published var tags: [Int: [Tag]] = [:] // Diccionario de tags por product_id
    @Published var filteredProducts: [Product] = [] // Lista filtrada para la UI
    @Published var searchText: String = "" // Texto de búsqueda bindeado a la UI

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil // ej: "Added to cart!"

    // MARK: - Dependencies
    let store: Store // Necesitamos saber para qué tienda buscar productos
    private let signInService: SignInUserService
    private let productService: ProductService
    private let tagService: TagService
    private let cartService: CartService
    private let cartProductService: CartProductService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        store: Store,
        signInService: SignInUserService,
        productService: ProductService = ProductService.shared,
        tagService: TagService = TagService.shared,
        cartService: CartService = CartService.shared,
        cartProductService: CartProductService = CartProductService.shared
    ) {
        self.store = store
        self.signInService = signInService
        self.productService = productService
        self.tagService = tagService
        self.cartService = cartService
        self.cartProductService = cartProductService
        print("🛒 ProductController initialized for store: \(store.name)")

        // Configurar la reacción a los cambios de búsqueda y productos
        setupFiltering()
    }

    // MARK: - Filtering Logic
    private func setupFiltering() {
        // Combina los cambios en el texto de búsqueda y la lista de productos
        Publishers.CombineLatest($searchText, $products)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Pequeña espera
            .map { searchText, products in
                // Aplica el filtro
                if searchText.isEmpty {
                    return products // Sin búsqueda, muestra todos
                } else {
                    return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                }
            }
            .assign(to: &$filteredProducts) // Asigna el resultado a la lista publicada filtrada
    }


    // MARK: - Data Loading
    func loadProductsAndTags() {
        guard !isLoading else { return } // Prevenir cargas múltiples simultáneas
        print("⏳ Loading products and tags for store ID: \(store.store_id)...")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.successMessage = nil
        }

        productService.fetchProducts(for: store.store_id) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // La carga principal de productos terminó (aunque falten tags)
                // Podríamos poner isLoading = false aquí o esperar a los tags

                switch result {
                case .success(let fetchedProducts):
                    print("✅ Fetched \(fetchedProducts.count) products.")
                    self.products = fetchedProducts // Actualiza la lista original (dispara el filtro)
                    // Ahora busca los tags para cada producto
                    self.fetchAllTags(for: fetchedProducts)

                case .failure(let error):
                    print("❌ Failed to fetch products:", error.localizedDescription)
                    self.errorMessage = "Could not load products."
                    self.isLoading = false // Termina la carga si falla aquí
                }
            }
        }
    }

    private func fetchAllTags(for productsToFetch: [Product]) {
        // Si no hay productos, termina la carga
        if productsToFetch.isEmpty {
             DispatchQueue.main.async { self.isLoading = false }
             return
        }

        let group = DispatchGroup() // Para saber cuándo terminan todas las llamadas de tags

        for product in productsToFetch {
            group.enter() // Entra al grupo antes de iniciar la llamada
            tagService.fetchTags(for: product.product_id) { [weak self] result in
                guard let self = self else { group.leave(); return } // Asegúrate de salir del grupo
                DispatchQueue.main.async {
                    switch result {
                    case .success(let fetchedTags):
                        self.tags[product.product_id] = fetchedTags // Actualiza el diccionario de tags
                    case .failure(let error):
                        // Podrías decidir mostrar un error o simplemente omitir los tags para ese producto
                        print("⚠️ Failed to fetch tags for product \(product.product_id):", error.localizedDescription)
                        self.tags[product.product_id] = [] // Poner vacío si falla?
                    }
                    group.leave() // Sale del grupo al completar la llamada (éxito o fallo)
                }
            }
        }

        // Notifica cuando todas las llamadas de tags hayan terminado
        group.notify(queue: .main) { [weak self] in
            print("✅ All tag fetches completed.")
            self?.isLoading = false // Termina la carga general aquí
        }
    }


    // MARK: - Actions
    func addToCart(product: Product) {
        guard let userId = signInService.userId else {
            print("❌ Cannot add to cart, user not logged in.")
            self.errorMessage = "Please sign in first."
            self.successMessage = nil
            return
        }

        // Opcional: Indicar carga específica para esta acción
        print("⏳ Adding product \(product.product_id) to cart for user \(userId)...")
        self.errorMessage = nil
        self.successMessage = nil


        // 1. Obtener carrito activo
        cartService.fetchActiveCart(for: userId) { [weak self] cartResult in
            guard let self = self else { return }

            switch cartResult {
            case .success(let cart):
                // 2. Añadir producto al carrito obtenido
                self.addProductToSpecificCart(cartId: cart.cart_id, productId: product.product_id)

            case .failure(let error):
                print("❌ Failed to find active cart:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.errorMessage = "Could not find your cart to add the item."
                }
            }
        }
    }

    private func addProductToSpecificCart(cartId: Int, productId: Int) {
         cartProductService.addProductToCart(cartID: cartId, productID: productId) { [weak self] addResult in
             guard let self = self else { return }
             DispatchQueue.main.async {
                switch addResult {
                case .success:
                    print("✅ Product \(productId) added to cart \(cartId).")
                    self.successMessage = "Item added to cart!"
                    // Limpia el mensaje de éxito después de un tiempo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.successMessage == "Item added to cart!" { // Solo si no ha cambiado
                           self.successMessage = nil
                        }
                    }
                case .failure(let error):
                    print("❌ Failed to add product \(productId) to cart \(cartId):", error.localizedDescription)
                    // Podría ser un error de duplicado, conexión, etc.
                    self.errorMessage = "Failed to add item: \(error.localizedDescription)"
                 }
            }
        }
    }
}
