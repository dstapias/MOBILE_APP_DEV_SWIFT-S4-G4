//
//  CheckoutView.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import SwiftUI

struct CheckoutView: View {

    // El controlador es la fuente de verdad. @StateObject gestiona su ciclo de vida.
    @StateObject private var controller: CheckoutController

    // El EnvironmentObject sólo se necesita para pasarlo al controller durante la inicialización.
    // Ya no se usa directamente en el cuerpo o métodos de la vista.

    // *** IMPORTANTE: Cómo inicializar esta vista ***
    // Debes crear el controller en la vista *padre* y pasarlo aquí.
    // Mira el ejemplo de la 'VistaPadre' al final.
    init(controller: CheckoutController) {
        _controller = StateObject(wrappedValue: controller)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Checkout")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack {
                    Text("Delivery")
                        .font(.subheadline)
                    Spacer()
                    // Leer del controller
                    Text(controller.deliveryMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    // Podrías añadir un botón para cambiarlo que llame a controller.setDeliveryMethod(...) si fuera necesario
                }

                Divider()

                HStack {
                    Text("Payment")
                        .font(.subheadline)
                    Spacer()
                     // Leer del controller
                    Text(controller.paymentMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    // Podrías añadir un botón para cambiarlo que llame a controller.setPaymentMethod(...) si fuera necesario
                }

                Divider()

                HStack {
                    Text("Total Cost")
                        .fontWeight(.semibold)
                    Spacer()
                     // Leer del controller
                    Text(String(format: "$%.2f", controller.totalCost))
                        .fontWeight(.bold)
                }

                Divider()

                Text("By placing an order you agree to our Terms And Conditions")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)

                // Mostrar mensaje de error si existe
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.vertical, 4)
                }

                Button(action: {
                    // ¡La acción es simple! Solo llama al controller.
                    controller.confirmCheckout()
                }) {
                    HStack {
                        if controller.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 4)
                        }
                        Text("Confirm Checkout")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    // Reaccionar al estado de carga del controller
                    .background(controller.isLoading ? Color.gray : Color.green)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                 // Reaccionar al estado de carga del controller
                .disabled(controller.isLoading)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
             // Reaccionar al estado del controller para la navegación
            .fullScreenCover(isPresented: $controller.showOrderAccepted) {
                // Puedes pasar el ID si la vista lo necesita
                OrderAcceptedView()
            }
        }
        // Ya no hay lógica `createOrder` ni `@State`s complejos aquí.
    }
}
