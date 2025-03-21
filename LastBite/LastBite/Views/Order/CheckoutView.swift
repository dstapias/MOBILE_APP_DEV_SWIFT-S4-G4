//
//  CheckoutView.swift
//  LastBite
//
//  Created by Andrés Romero on 20/03/25.
//

import SwiftUI

struct CheckoutView: View {
    // Recibimos los ítems para calcular el costo total
    let cartItems: [CartItem]
    
    // Opciones seleccionadas (puedes hacerlas dinámicas si gustas)
    @State private var deliveryMethod: String = "In-store Pickup"
    @State private var paymentMethod: String = "PSE"
    
    // Controla la presentación de la pantalla de Order Accepted
    @State private var showOrderAccepted = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                
                // Título principal
                Text("Checkout")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Delivery
                HStack {
                    Text("Delivery")
                        .font(.subheadline)
                    Spacer()
                    Text(deliveryMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                
                Divider()
                
                // Payment
                HStack {
                    Text("Payment")
                        .font(.subheadline)
                    Spacer()
                    Text(paymentMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                
                Divider()
                
                // Cálculo del total
                let totalCost = cartItems.reduce(0) { partialResult, item in
                    partialResult + (item.price * Double(item.quantity))
                }
                
                HStack {
                    Text("Total Cost")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "$%.2f", totalCost))
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // Términos y condiciones
                Text("By placing an order you agree to our Terms And Conditions")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                // Botón de confirmación
                Button(action: {
                    showOrderAccepted = true
                }) {
                    Text("Confirm Checkout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        // Presentamos OrderAcceptedView en pantalla completa
        .fullScreenCover(isPresented: $showOrderAccepted) {
            OrderAcceptedView()
        }
    }
}

// MARK: - Vista de previsualización
/*struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        // Ejemplo con algunos ítems de prueba
        CheckoutView(
            cartItems: [
                CartItem(name: "Bell Pepper Red", weight: "1kg", quantity: 1, price: 4.99, imageName: "red_pepper"),
                CartItem(name: "Organic Bananas", weight: "12kg", quantity: 2, price: 3.00, imageName: "bananas")
            ]
        )
    }
}
*/
