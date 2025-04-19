//
//  ProductController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor // Asegura updates en hilo principal
class ProductController: ObservableObject {

    // MARK: - Published State
    @Published var products: [Product] = [] // Lista original (fuente para el filtro)
    @Published var tags: [Int: [Tag]] = [:] // Diccionario de tags por product.id
    @Published var filteredProducts: [Product] = [] // Lista que muestra la UI
    @Published var searchText: String = "" // Para el TextField

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil // Para "Added to cart!"

    // MARK: - Dependencies (Ahora Repositorios)
    let store: Store // La tienda actual
    private let signInService: SignInUserService
    private let productRepository: ProductRepository // <- Usa Repo
    private let tagRepository: TagRepository       // <- Usa Repo
    private let cartRepository: CartRepository     // <- Usa Repo
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization (Recibe Repositorios)
    init(
        store: Store,
        signInService: SignInUserService,
        productRepository: ProductRepository, // <- Inyecta Repo
        tagRepository: TagRepository,       // <- Inyecta Repo
        cartRepository: CartRepository      // <- Inyecta Repo
    ) {
        self.store = store
        self.signInService = signInService
        self.productRepository = productRepository
        self.tagRepository = tagRepository
        self.cartRepository = cartRepository
        print("📦 ProductController initialized with Repositories for store: \(store.name)")
        setupFiltering() // Configura el filtro reactivo
    }

    // MARK: - Filtering Logic (Sin Cambios Internos)
    // Sigue funcionando con las propiedades @Published locales
    private func setupFiltering() {
        Publishers.CombineLatest($searchText, $products)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { searchText, products in
                if searchText.isEmpty {
                    return products
                } else {
                    return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                }
            }
            .assign(to: &$filteredProducts)
    }

    // MARK: - Data Loading (Async con Repos y TaskGroup)

    /// Carga productos y luego sus tags en paralelo.
    func loadProductsAndTags() {
        // Evita recargar si ya está cargando
        guard !isLoading else { return }
        print("⏳ Loading products and tags via Repositories for store ID: \(store.store_id)...")
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task { // Lanza la tarea principal async
            do {
                // 1. Obtener Productos
                print("   Fetching products...")
                let fetchedProducts = try await productRepository.fetchProducts(for: store.store_id)
                self.products = fetchedProducts // Actualiza la lista original (dispara filtro)
                print("   ✅ Fetched \(fetchedProducts.count) products.")

                // 2. Obtener Tags para los productos obtenidos (en paralelo)
                if !fetchedProducts.isEmpty {
                    print("   Fetching tags for \(fetchedProducts.count) products...")
                    // Usa TaskGroup para lanzar llamadas concurrentes para los tags
                    var fetchedTagsDict: [Int: [Tag]] = [:]
                    try await withThrowingTaskGroup(of: (Int, [Tag]).self) { group in
                        for product in fetchedProducts {
                            // Añade una tarea al grupo por cada producto
                            group.addTask {
                                print("      Fetching tags for product \(product.id)...")
                                // Llama al repo de tags
                                let tags = try await self.tagRepository.fetchTags(for: product.id)
                                // Devuelve el ID del producto y sus tags
                                return (product.id, tags)
                            }
                        }
                        // Recolecta los resultados de cada tarea a medida que terminan
                        for try await (productId, tags) in group {
                            fetchedTagsDict[productId] = tags
                        }
                    } // El TaskGroup maneja errores automaticamente (si uno falla, lanza)
                    self.tags = fetchedTagsDict // Actualiza el diccionario de tags
                    print("   ✅ Fetched tags completed.")
                } else {
                    self.tags = [:] // Limpia tags si no hay productos
                }

                print("✅ Products and Tags loaded successfully.")

            } catch let error as ServiceError {
                print("❌ Failed to load products/tags: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                 self.products = [] // Limpia en caso de error
                 self.tags = [:]
            } catch {
                print("❌ Unexpected error loading products/tags: \(error.localizedDescription)")
                self.errorMessage = "Failed to load products."
                 self.products = []
                 self.tags = [:]
            }
            // Termina la carga general
            self.isLoading = false
        }
    }

    // Ya no necesitamos fetchAllTags como función separada gracias a TaskGroup

    // MARK: - Actions (Async con Repositorio)

    /// Añade un producto al carrito usando CartRepository.
    func addToCart(product: Product) async { // La función es async
        guard let userId = signInService.userId else {
            errorMessage = "Please sign in first."
            successMessage = nil
            return
        }
        // Puedes añadir un estado isLoading específico para esta acción si quieres
        // pero por simplicidad usaremos el general por ahora.
        guard !isLoading else { return } // Evita si ya hay otra carga en curso

        print("🛒 Adding product \(product.id) to cart via Repository...")
        // isLoading = true // Podrías activar aquí si no usaras el flag general
        errorMessage = nil
        successMessage = nil

        do {
            // 1. Obtener carrito activo (usando repo)
            let cart = try await cartRepository.fetchActiveCart(for: userId)

            // 2. Añadir producto con cantidad 1 (usando repo)
            //    (Asume que tu repo/servicio maneja la lógica de añadir/actualizar)
            try await cartRepository.addProductToCart(cartId: cart.id, productId: product.id, quantity: 1)

            // Éxito
            print("✅ Product \(product.id) added to cart \(cart.id) via Repo.")
            successMessage = "\(product.name) added to cart!"
            // Limpia mensaje después de un tiempo
            Task {
                 try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
                 if self.successMessage != nil { self.successMessage = nil }
            }
        } catch let error as ServiceError {
             print("❌ Failed to add product \(product.id) to cart: \(error.localizedDescription)")
             errorMessage = "Failed to add item: \(error.localizedDescription)"
        } catch {
            print("❌ Unexpected error adding product \(product.id) to cart: \(error.localizedDescription)")
            errorMessage = "Could not add item to cart."
        }
        // isLoading = false // Desactiva si usaste un flag específico
    }

    // addProductToSpecificCart ya no es necesario, la lógica está en addToCart
}

// --- Asegúrate que existan ---
// protocol ProductRepository { ... }
// class APIProductRepository: ProductRepository { ... }
// protocol TagRepository { ... }
// class APITagRepository: TagRepository { ... }
// protocol CartRepository { func fetchActiveCart... func addProductToCart... }
// class APICartRepository: CartRepository { ... }
// struct Product, Tag, Cart, CartItem, CategoryItemData, Store (Identifiable, Equatable, Codable)
// class SignInUserService: ObservableObject { ... }
// enum ServiceError: Error, LocalizedError { ... }
