import SwiftUI
import SDWebImageSwiftUI

struct ProductView: View {
    // Dependencias (sin cambios)
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var controller: ProductController

    // Inicializador (sin cambios, asume que funciona como lo configuraste)
    init(store: Store) {
            // 1. Crear instancias de TODOS los repositorios necesarios
            let productRepository = APIProductRepository()
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

            // 3. Asignar al StateObject wrapper
            self._controller = StateObject(wrappedValue: productController)
            print("🛒 ProductView initialized and injected Repositories into ProductController for store: \(store.name)")
        }

    // --- Cuerpo Principal (Simplificado) ---
    var body: some View {
        VStack { // VStack principal
            // 1. Barra de búsqueda extraída
            searchBar

            // 2. Mensajes de estado extraídos
            infoMessages

            // 3. Grid de productos extraído
            productsGrid
        }
        // Modificadores aplicados al VStack principal
        .navigationTitle(controller.store.name)
        .onAppear {
            controller.loadProductsAndTags()
        }
        // Animaciones aplicadas al VStack principal (afectarán a sus sub-vistas)
        .animation(.default, value: controller.filteredProducts)
        .animation(.default, value: controller.isLoading)
        .animation(.default, value: controller.errorMessage)
        .animation(.default, value: controller.successMessage)
    } // Fin body

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
        // Nota: No pongas animaciones aquí si ya las aplicas al contenedor principal
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
                 // La transición es mejor aplicarla aquí si quieres que solo afecte al mensaje
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
            .padding(.vertical) // Padding para el contenido del ScrollView
        }
    }

}

// --- ProductCard (Sin cambios necesarios si ya recibía la closure) ---
// struct ProductCard: View { ... }
struct ProductCard: View {
    let product: Product // Recibe el producto
    let tags: [Tag]      // Recibe los tags para este producto
    let onAddToCart: () -> Void // Recibe la acción a ejecutar

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WebImage(url: URL(string: product.image)) // Usa la imagen del producto
                .resizable()
                .indicator(.activity) // Muestra un indicador mientras carga
                .transition(.fade(duration: 0.5)) // Animación de aparición
                .scaledToFit()
                .frame(height: 100) // Ajusta la altura según necesites
                .frame(maxWidth: .infinity) // Ocupa el ancho disponible
                .clipped() // Recorta si la imagen es más grande
                .cornerRadius(8)

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
        // Define un tamaño fijo o flexible para la tarjeta
        // .frame(width: 160, height: 220) // Tamaño fijo como antes
        .frame(maxWidth: .infinity) // Ocupa el ancho de la columna
        .frame(height: 230) // Altura fija para consistencia
        .background(Color.white) // Fondo blanco
        .cornerRadius(12) // Bordes redondeados de la tarjeta
        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2) // Sombra suave
    }
}


// --- Preview ---
struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        // Crea un store de ejemplo
        let exampleStore = Store(
            store_id: 1, name: "Preview Store", address: "123 Preview St",
            latitude: 0, longitude: 0, logo: "https://via.placeholder.com/150", nit: "123"
        )
        // Crea un mock de SignInUserService para la preview
        let mockSignInService = SignInUserService.shared // O un mock real

        // Si ProductView necesita signInService en su init:
        // ProductView(store: exampleStore, signInService: mockSignInService)
        // Si no (como en la solución temporal):
        ProductView(store: exampleStore)
             // La preview necesita el servicio en el entorno si alguna subvista o el controller lo usa implícitamente
            .environmentObject(mockSignInService)
    }
}
