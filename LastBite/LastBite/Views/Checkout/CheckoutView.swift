//
//  CheckoutView.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import SwiftUI

struct CheckoutView: View {
    // 1. Controller como StateObject (sin cambios en declaración)
    @StateObject private var controller: CheckoutController

    // El EnvironmentObject SÍ se necesita aquí si la VISTA PADRE no pasa explícitamente
    // el signInService al crear esta vista. Asumiremos que el controller
    // puede acceder al Singleton o que lo pasamos en el init.
    // @EnvironmentObject var signInService: SignInUserService

    // 2. Inicializador ACTUALIZADO: Recibe datos, crea Controller e inyecta Repositorios
    init(cartItems: [CartItem], cartId: Int /*, signInService: SignInUserService - opcional si se pasa */) {
        // 1. Crear instancias de los repositorios necesarios
        let orderRepository = APIOrderRepository()
        let cartRepository = APICartRepository()

        // 2. Obtener otras dependencias (ej: singleton)
        let signInService = SignInUserService.shared

        // 3. Crear el CheckoutController con sus dependencias ACTUALIZADAS
        let checkoutController = CheckoutController(
            cartItems: cartItems,
            cartId: cartId,
            signInService: signInService,    // Pasa la dependencia
            orderRepository: orderRepository, // <- Inyecta Order Repo
            cartRepository: cartRepository   // <- Inyecta Cart Repo
        )

        // 4. Asignar al StateObject wrapper
        self._controller = StateObject(wrappedValue: checkoutController)
        print("🛒 CheckoutView initialized and injected Repositories into Controller.")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Título (sin cambios)
                Text("Checkout").font(.title2).fontWeight(.semibold)

                // Delivery Method (sin cambios, lee del controller)
                HStack { Text("Delivery"); Spacer(); Text(controller.deliveryMethod).foregroundColor(.gray).font(.subheadline) }
                Divider()

                // Payment Method (sin cambios, lee del controller)
                HStack { Text("Payment"); Spacer(); Text(controller.paymentMethod).foregroundColor(.gray).font(.subheadline) }
                Divider()

                // Total Cost (sin cambios, lee del controller)
                HStack { Text("Total Cost").fontWeight(.semibold); Spacer(); Text(String(format: "$%.2f", controller.totalCost)).fontWeight(.bold) }
                Divider()

                // Texto legal (sin cambios)
                Text("By placing an order you agree to our Terms And Conditions")
                    .font(.footnote).foregroundColor(.gray).multilineTextAlignment(.leading)

                // Mensaje de error (sin cambios, lee del controller)
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red).font(.footnote).padding(.vertical, 4)
                }

                // --- Botón Confirmar Checkout ACTUALIZADO ---
                Button(action: {
                    // Llama al método async del controller DENTRO de una Task
                    Task {
                        await controller.confirmCheckout()
                    }
                }) {
                    HStack { // Contenido del botón (sin cambios)
                        if controller.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding(.trailing, 4)
                        }
                        Text("Confirm Checkout").fontWeight(.bold)
                    }
                    .foregroundColor(.white).padding()
                    .frame(maxWidth: .infinity)
                    .background(controller.isLoading ? Color.gray : Color.green).cornerRadius(8)
                }
                .padding(.top, 8)
                .disabled(controller.isLoading) // Estado disabled (sin cambios)

                Spacer() // Empuja todo hacia arriba

            } // Fin VStack
            .padding()
            .navigationBarTitleDisplayMode(.inline)
             // fullScreenCover (usa $controller.showOrderAccepted y la vista simplificada)
            .fullScreenCover(isPresented: $controller.showOrderAccepted) {
                 // Pasa el ID si lo necesitas, usa la vista simplificada con dismiss
                 OrderAcceptedView()
            }
        } // Fin NavigationStack (¿Es necesaria aquí si se presenta modalmente?)
          // Si CheckoutView SIEMPRE se presenta con .sheet o .fullScreenCover,
          // podrías quitar el NavigationStack de aquí dentro.
    } // Fin body
} // Fin struct CheckoutView

// --- Preview ---
struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        // Necesitas datos de ejemplo para la preview
        let exampleItems = [
            CartItem(productId: 101, name: "Apple", detail: "Fresh", quantity: 2, price: 1.50, imageUrl: ""),
            CartItem(productId: 102, name: "Banana", detail: "Organic", quantity: 3, price: 0.75, imageUrl: "")
        ]
        let exampleCartId = 55

        // El init ahora solo necesita items y cartId
        CheckoutView(cartItems: exampleItems, cartId: exampleCartId)
            // Añade el servicio al entorno para la preview si el controller lo necesita
            .environmentObject(SignInUserService.shared)
            // Podrías necesitar mockear repositorios si el controller los usa en init
    }
}

// --- Modelos y Vistas/Controllers referenciados ---
// Asegúrate que CartItem, Order, CheckoutController, APIOrderRepository, APICartRepository,
// SignInUserService, OrderAcceptedView estén definidos y accesibles.
