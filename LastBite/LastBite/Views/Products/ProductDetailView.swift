//
//  ProductDetailView.swift
//  LastBite
//
//  Created by Andrés Romero on 17/03/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProductDetailView: View {
    // 1. Controller como StateObject (Correcto)
    @StateObject private var controller: ProductDetailController

    // 2. Inicializador ACTUALIZADO que recibe Producto y crea Controller con REPOSITORIO (Correcto)
    init(product: Product) {
        // 1. Crea la instancia del Repositorio CONCRETO necesario
        let cartRepository = APICartRepository() // <- Crear Cart Repo

        // 2. (Opcional) Obtener otras dependencias (como el servicio de usuario)
        let signInService = SignInUserService.shared // Asume singleton

        // 3. Crea el Controller pasándole el producto y el repositorio
        let detailController = ProductDetailController(
            product: product,
            signInService: signInService,
            cartRepository: cartRepository
        )

        // 4. Asigna al StateObject wrapper
        self._controller = StateObject(wrappedValue: detailController)
        print("📦 ProductDetailView initialized and injected CartRepository into Controller for product: \(product.name)")
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                WebImage(url: URL(string: controller.product.image))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(controller.product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    HStack {
                        Spacer()
                        Text(String(format: "$%.2f", controller.product.unit_price))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Text("Quantity").font(.headline)
                    Spacer()
                    Stepper("Quantity", value: $controller.quantity, in: 1...10) // Rango ejemplo
                        .overlay(Text("\(controller.quantity)").padding(.horizontal, 20))
                        .labelsHidden()
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Detail").font(.headline)
                    Text(controller.product.detail ?? "No description available.")
                        .font(.body).foregroundColor(.secondary)
                }
                .padding(.horizontal)

                 VStack {
                     if let message = controller.successMessage {
                         Text(message)
                            .font(.footnote).foregroundColor(.green)
                            .padding(.vertical, 5)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                     }
                     if let message = controller.errorMessage {
                         Text(message)
                            .font(.footnote).foregroundColor(.red)
                            .padding(.vertical, 5)
                     }
                 }
                 .frame(maxWidth: .infinity, alignment: .center)
                 .animation(.default, value: controller.successMessage)
                 .animation(.default, value: controller.errorMessage)


                Button(action: {
                    Task {
                       await controller.addToCart()
                    }
                }) {
                    ZStack {
                        if controller.isLoading {
                             ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Add To Basket").fontWeight(.bold).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(controller.isLoading ? Color.gray : Color.green).cornerRadius(8)
                }
                .padding(.horizontal).padding(.top, 8)
                .disabled(controller.isLoading)

            }
            .padding(.vertical)
        }
        .navigationTitle("Product Detail") // Título
        .navigationBarTitleDisplayMode(.inline) // Modo del título
    }
}

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

// --- Preview (Correcta) ---
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
             ProductDetailView(product: Product(
                 product_id: 1, name: "Preview Apple", detail: "Preview Description",
                 unit_price: 1.99, image: "https://via.placeholder.com/300", score: 4.0, store_id: 1, product_type: "Fruit"
             ))
        }
       .environmentObject(SignInUserService.shared)
    }
}
