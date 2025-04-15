//
//  ProductDetailView.swift
//  LastBite
//
//  Created by Andrés Romero on 17/03/25.
//

import SwiftUI
import SDWebImageSwiftUI // Si la usas

struct ProductDetailView: View {
    // 1. Controller como StateObject
    @StateObject private var controller: ProductDetailController

    // 2. El estado de cantidad se elimina, se usa el del controller
    // @State private var quantity: Int = 1 // ELIMINADO

    // 3. Los datos harcodeados se eliminan

    // 4. Inicializador que recibe el Producto y crea el Controller
    //    Necesitará acceso a los servicios compartidos o que se los pasen.
    init(product: Product /*, signInService: SignInUserService - si se pasa explícitamente */) {
        // Crea el controller aquí, pasándole el producto y los servicios necesarios
        // Asume que los servicios usan singletons o son accesibles
        self._controller = StateObject(wrappedValue: ProductDetailController(product: product))
        print("📦 ProductDetailView initialized for product: \(product.name)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // 5. Imagen del producto (usa datos del controller.product y WebImage)
                WebImage(url: URL(string: controller.product.image))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250) // Ajusta según necesites
                    .clipped() // Evita que se desborde si la imagen es muy alta

                // 6. Título e info (usa datos del controller.product)
                VStack(alignment: .leading, spacing: 4) {
                    Text(controller.product.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        // Asume que tienes una propiedad 'weight' o similar en Product
                        // Text(controller.product.weight ?? "") // Ejemplo
                        // .font(.subheadline)
                        // .foregroundColor(.secondary)

                        Spacer()

                        Text(String(format: "$%.2f", controller.product.unit_price))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)

                // 7. Sección Cantidad (bindeado al controller)
                HStack(spacing: 16) {
                    Text("Quantity") // Etiqueta explícita
                        .font(.headline)

                    Spacer() // Empuja el Stepper a la derecha

                    Stepper("Quantity", value: $controller.quantity, in: 1...10) // Rango de ejemplo
                        // Mostrar la cantidad seleccionada
                        .overlay(Text("\(controller.quantity)").padding(.horizontal, 20)) // Muestra el número
                        .labelsHidden() // Oculta la etiqueta por defecto del Stepper
                }
                .padding(.horizontal)

                // 8. Detalles del Producto (usa datos del controller.product)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Detail")
                        .font(.headline)

                    // Asume que tienes 'description' en tu modelo Product
                    Text(controller.product.detail ?? "No description available.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // 9. Tags (si existen en tu modelo Product)
                // if let tags = controller.product.tags, !tags.isEmpty {
                //     VStack(alignment: .leading, spacing: 8) {
                //         Text("Tags").font(.headline)
                //         ScrollView(.horizontal, showsIndicators: false) {
                //             HStack(spacing: 8) {
                //                 ForEach(tags) { tag in // Asume Tag: Identifiable
                //                     TagView(text: tag.value)
                //                 }
                //             }
                //         }
                //     }
                //     .padding(.horizontal)
                // }

                // 10. Rating (si existe en tu modelo Product)
                // VStack(alignment: .leading, spacing: 8) {
                //     Text("Reviews").font(.headline)
                //     HStack {
                //         ForEach(0..<Int(controller.product.score.rounded())) { _ in
                //             Image(systemName: "star.fill").foregroundColor(.yellow)
                //         }
                //          ForEach(Int(controller.product.score.rounded())..<5) { _ in
                //              Image(systemName: "star").foregroundColor(.yellow)
                //          }
                //         Text(String(format:"%.1f/5", controller.product.score))
                //             .font(.subheadline).foregroundColor(.secondary)
                //     }
                // }
                // .padding(.horizontal)


                // --- Feedback de la Acción ---
                 VStack {
                     if let message = controller.successMessage {
                         Text(message)
                             .font(.footnote)
                             .foregroundColor(.green)
                             .padding(.vertical, 5)
                             .transition(.opacity.combined(with: .move(edge: .bottom)))
                     }
                     if let message = controller.errorMessage {
                         Text(message)
                             .font(.footnote)
                             .foregroundColor(.red)
                             .padding(.vertical, 5)
                     }
                 }
                 .frame(maxWidth: .infinity, alignment: .center)
                 .animation(.default, value: controller.successMessage)
                 .animation(.default, value: controller.errorMessage)


                // 11. Botón "Add To Basket" (llama al controller)
                Button(action: {
                    controller.addToCart()
                }) {
                    ZStack {
                        // Muestra ProgressView si está cargando
                        if controller.isLoading {
                             ProgressView()
                                 .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Add To Basket")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(controller.isLoading ? Color.gray : Color.green) // Color cambia si carga
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .disabled(controller.isLoading) // Deshabilita si está cargando

            } // Fin VStack principal
            .padding(.vertical) // Padding para todo el contenido del ScrollView
        } // Fin ScrollView
        .navigationTitle("Product Detail") // Título
        .navigationBarTitleDisplayMode(.inline) // Modo del título
    } // Fin body
} // Fin struct ProductDetailView

// --- Vista TagView (Sin cambios) ---
struct TagView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(12)
    }
}

// --- Preview ---
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Crea un producto de ejemplo para la preview
            ProductDetailView(product: Product(
                product_id: 1,
                name: "Fresh Red Apple",
                detail: "A very fresh and crunchy red apple, perfect for a healthy snack.",
                unit_price: 4.99,
                image: "https://via.placeholder.com/300.png/FF0000/FFFFFF?text=Apple", // Placeholder URL
                score: 4.5,
                store_id: 10,
                product_type: "Fruit"
                // ,tags: [Tag(tag_id: 1, value: "Fresh"), Tag(tag_id: 2, value: "Organic")] // Ejemplo si tienes tags
            ))
        }
        // Necesita el servicio si el controller lo usa implícitamente
       .environmentObject(SignInUserService.shared)
       // Podrías necesitar mockear otros servicios si el controller los usa directamente en init
       // .environmentObject(CartService.shared)
       // .environmentObject(CartProductService.shared)
    }
}
