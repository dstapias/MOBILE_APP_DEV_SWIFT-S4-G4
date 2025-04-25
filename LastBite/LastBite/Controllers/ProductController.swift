//
//  ProductController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor 
class ProductController: ObservableObject {

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var tags: [Int: [Tag]] = [:]
    @Published var filteredProducts: [Product] = []
    @Published var searchText: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    // MARK: - Dependencies (Ahora Repositorios)
    let store: Store
    private let signInService: SignInUserService
    private let productRepository: ProductRepository
    private let tagRepository: TagRepository
    private let cartRepository: CartRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization (Recibe Repositorios)
    init(
        store: Store,
        signInService: SignInUserService,
        productRepository: ProductRepository,
        tagRepository: TagRepository,
        cartRepository: CartRepository
    ) {
        self.store = store
        self.signInService = signInService
        self.productRepository = productRepository
        self.tagRepository = tagRepository
        self.cartRepository = cartRepository
        print("📦 ProductController initialized with Repositories for store: \(store.name)")
        setupFiltering()
    }

    // MARK: - Filtering Logic
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

        Task {
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


    // MARK: - Actions (Async con Repositorio)

    /// Añade un producto al carrito usando CartRepository.
    func addToCart(product: Product) async { // La función es async
        guard let userId = signInService.userId else {
            errorMessage = "Please sign in first."
            successMessage = nil
            return
        }
        guard !isLoading else { return } // Evita si ya hay otra carga en curso

        print("🛒 Adding product \(product.id) to cart via Repository...")
        errorMessage = nil
        successMessage = nil

        do {
            // 1. Obtener carrito activo (usando repo)
            let cart = try await cartRepository.fetchActiveCart(for: userId)

            // 2. Añadir producto con cantidad 1 (usando repo)
            try await cartRepository.addProductToCart(cartId: cart.id, product: product, quantity: 1)

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
    }

}
