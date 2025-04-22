//
//  CheckoutView.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import SwiftUI

struct CheckoutView: View {
    @StateObject private var controller: CheckoutController
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = true


    init(cartItems: [CartItem], cartId: Int) {
        // 1. Crear instancias de los repositorios necesarios
        let orderRepository = APIOrderRepository()
        let cartRepository = APICartRepository()

        let signInService = SignInUserService.shared

        let checkoutController = CheckoutController(
            cartItems: cartItems,
            cartId: cartId,
            signInService: signInService,
            orderRepository: orderRepository,
            cartRepository: cartRepository
        )

        // 4. Asignar al StateObject wrapper
        self._controller = StateObject(wrappedValue: checkoutController)
        print("🛒 CheckoutView initialized and injected Repositories into Controller.")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Checkout").font(.title2).fontWeight(.semibold)

                HStack { Text("Delivery"); Spacer(); Text(controller.deliveryMethod).foregroundColor(.gray).font(.subheadline) }
                Divider()

                HStack { Text("Payment"); Spacer(); Text(controller.paymentMethod).foregroundColor(.gray).font(.subheadline) }
                Divider()

                HStack { Text("Total Cost").fontWeight(.semibold); Spacer(); Text(String(format: "$%.2f", controller.totalCost)).fontWeight(.bold) }
                Divider()

                Text("By placing an order you agree to our Terms And Conditions")
                    .font(.footnote).foregroundColor(.gray).multilineTextAlignment(.leading)

                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red).font(.footnote).padding(.vertical, 4)
                }

                Button(action: {
                    // Llama al método async del controller DENTRO de una Task
                    Task {
                        await controller.confirmCheckout()
                    }
                }) {
                    HStack {
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
                .disabled(controller.isLoading)

                Spacer()

            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $controller.showOrderAccepted,
                             onDismiss: {
                                 dismiss()
                             }) {
                 OrderAcceptedView()
            }
                             .onChange(of: isLoggedIn) { logged in
                                 if !logged { dismiss() }
                             }
        }
    }
}

struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleItems = [
            CartItem(productId: 101, name: "Apple", detail: "Fresh", quantity: 2, price: 1.50, imageUrl: ""),
            CartItem(productId: 102, name: "Banana", detail: "Organic", quantity: 3, price: 0.75, imageUrl: "")
        ]
        let exampleCartId = 55

        CheckoutView(cartItems: exampleItems, cartId: exampleCartId)
            .environmentObject(SignInUserService.shared)
    }
}
