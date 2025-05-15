import SwiftUI
import SDWebImageSwiftUI

struct ProductView: View {
    // Dependencias (sin cambios)
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var controller: ProductController
    @StateObject private var storeController: StoreController
    
    @Environment(\.dismiss) private var dismiss


    @State private var navigateToCreateProduct = false
    @State private var navigateToUpdateStore = false
    
    let owned: Bool // <- New flag to control owner access
    let homeController: HomeController

    // Inicializador (sin cambios, asume que funciona como lo configuraste)
    init(store: Store, owned: Bool = false, homeController: HomeController) {
            // 1. Crear instancias de TODOS los repositorios necesarios
            let productRepository = APIProductRepository()
            let storeRepository = APIStoreRepository()
            let tagRepository = APITagRepository()
            let cartRepository = APICartRepository()
            let signInService = SignInUserService.shared // Obtener servicio

            // 2. Crear el ProductController inyectando TODO
            let productController = ProductController(
                store: store,
                signInService: signInService,
                productRepository: productRepository, // <- Inyecta Repo Producto
                tagRepository: tagRepository,         // <- Inyecta Repo Tag
                cartRepository: cartRepository        // <- Inyecta Repo Carrito
            )
        
        let storeController = StoreController(storeRepository: storeRepository)

            // 3. Asignar al StateObject wrapper
            self._controller = StateObject(wrappedValue: productController)
        self._storeController = StateObject(wrappedValue: storeController)
            self.owned = owned
        self.homeController = homeController
        
            print("🛒 ProductView initialized and injected Repositories into ProductController for store: \(store.name)")
        print("🛒 ProductView init: HomeController instance received = \(Unmanaged.passUnretained(homeController).toOpaque()) for store: \(store.name)")

        }

    // --- Cuerpo Principal (Simplificado) ---
    var body: some View {
        VStack {
            // 1. Barra de búsqueda extraída
            searchBar

            // 2. Mensajes de estado extraídos
            infoMessages

            // 3. Grid de productos extraído
            productsGrid
        }
        .navigationTitle(controller.store.name)
        .onAppear {
            controller.loadProductsAndTags()
        }
        .animation(.default, value: controller.filteredProducts)
        .animation(.default, value: controller.isLoading)
        .animation(.default, value: controller.errorMessage)
        .animation(.default, value: controller.successMessage)
        .toolbar {
            if owned {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                navigateToUpdateStore = true
                            } label: {
                                Label("Update Store", systemImage: "pencil.circle.fill")
                            }

                            Button {
                                navigateToCreateProduct = true
                            } label: {
                                Label("Add Product", systemImage: "plus.circle.fill")
                            }
                        } label: {

                            Label("Actions", systemImage: "ellipsis.circle")
                        }
                        .tint(.primaryGreen)
                    }
                }
        }
        .navigationDestination(isPresented: $navigateToCreateProduct) {
            CreateProductView(store: controller.store, controller: controller)
        }
        .navigationDestination(isPresented: $navigateToUpdateStore) {
            UpdateStoreView(store: controller.store, controller: storeController, homeController: homeController, onDismissAfterUpdate: {
                // Este closure se ejecuta DESPUÉS de que la alerta de UpdateStoreView
                // ha llamado a homeController.loadInitialData() y ANTES de que UpdateStoreView llame a su propio dismiss().
                print("🛍️ ProductView: Callback 'onDismissAfterUpdate' from UpdateStoreView received.")
                
                // Iniciar una tarea para obtener la tienda actualizada y luego actualizar la UI
                Task {
                    do {
                        // 1. Re-obtener la tienda actualizada usando el StoreController
                        let fetchedUpdatedStore = try await self.storeController.fetchStoreById(store_id: controller.store.store_id)
                        
                        print("🛍️ ProductView: Fetched store name from getStoreById: '\(fetchedUpdatedStore.name)'")
                        
                        // 2. Actualizar el ProductController interno con la tienda fresca.
                        //    Esto hará que el .navigationTitle(controller.store.name) se actualice.
                        self.controller.updateStore(fetchedUpdatedStore) // Llama al método que confirmaste que tienes
                        
                        // 3. Cambiar a la pestaña de Home (índice 0)
                        print("🛍️ ProductView: Changing tab to 0 (Home).")                        
                        // 4. Limpiar el mensaje de éxito en StoreController para evitar re-triggering.
                        //    Esto es importante si StoreController.successMessage se usa para otras cosas.
                        await MainActor.run { self.storeController.successMessage = nil }
                        
                    } catch {
                        print("🛍️ ProductView: Failed to re-fetch or update store details in ProductController: \(error.localizedDescription)")
                        // Opcionalmente, mostrar un error al usuario aquí si es apropiado.
                    }
                }
                // NO LLAMAR A dismiss() AQUÍ. UpdateStoreView se encarga de su propio cierre.
            })
        }
    }


    // --- Propiedades Computadas para las Secciones ---

    /// Construye la barra de búsqueda.
    private var searchBar: some View {
        TextField("Search Products", text: $controller.searchText)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top)
    }

    /// Construye la sección de mensajes de estado (carga, error, éxito).
    @ViewBuilder // Usa @ViewBuilder si tienes condicionales dentro
    private var infoMessages: some View {
        if controller.isLoading {
            ProgressView("Loading products...")
                .padding(.vertical, 5) // Ajusta padding
        }
        // Mostrar errores o mensajes de éxito
        if let message = controller.errorMessage {
            Text(message)
                .foregroundColor(.red)
                .font(.footnote)
                .padding(.horizontal)
                .padding(.bottom, 5) // Espacio antes del grid
        } else if let message = controller.successMessage {
             Text(message)
                .foregroundColor(.green)
                .font(.footnote)
                .padding(.horizontal)
                .padding(.bottom, 5)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    /// Construye el ScrollView con el grid de productos.
    private var productsGrid: some View {
        ScrollView {
            // El VStack y LazyVGrid internos están bien aquí
            VStack(alignment: .leading) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Itera sobre los productos filtrados del controller
                    ForEach(controller.filteredProducts) { product in
                        ProductCard(
                            product: product,
                            tags: controller.tags[product.product_id] ?? [],
                            onAddToCart: {
                                Task {
                                    await controller.addToCart(product: product)
                                }
                                }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

}

struct ProductCard: View {
    let product: Product // Recibe el producto
    let tags: [Tag]      // Recibe los tags para este producto
    let onAddToCart: () -> Void // Recibe la acción a ejecutar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImageView(
                urlString: product.image,
                width: UIScreen.main.bounds.width / 2 - 32, // Ajusta según tu grid
                height: 100,
                cornerRadius: 8
            )
            .frame(maxWidth: .infinity)

            Text(product.name) // Muestra el nombre del producto
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(2) // Limita a 2 líneas si es largo

            // Muestra los tags si existen
            if !tags.isEmpty {
                Text(tags.map { $0.value }.joined(separator: ", "))
                    .font(.caption) // Más pequeño para los tags
                    .foregroundColor(.gray)
                    .lineLimit(1) // Solo una línea para tags
            }

            // Spacer para empujar precio y botón hacia abajo
            Spacer()

            HStack {
                Text("$\(String(format: "%.2f", product.unit_price))") // Muestra el precio
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer() // Empuja el botón a la derecha

                Button(action: onAddToCart) { // Llama a la acción recibida
                    Image(systemName: "plus")
                        .font(.title2) // Tamaño del icono
                        .foregroundColor(.white)
                        .padding(8) // Padding dentro del botón
                        .background(Color.green)
                        .cornerRadius(8) // Bordes redondeados
                }
            }
        }
        .padding() // Padding general de la tarjeta
        .frame(maxWidth: .infinity) // Ocupa el ancho de la columna
        .frame(height: 230) // Altura fija para consistencia
        .background(Color.white) // Fondo blanco
        .cornerRadius(12) // Bordes redondeados de la tarjeta
        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2) // Sombra suave
    }
}


