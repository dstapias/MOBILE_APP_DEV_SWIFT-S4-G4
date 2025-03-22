import SwiftUI

struct CheckoutView: View {
    let cartItems: [CartItem]
    let cartId: Int

    @EnvironmentObject var signInService: SignInUserService
    @State private var deliveryMethod: String = "In-store Pickup"
    @State private var paymentMethod: String = "PSE"
    @State private var showOrderAccepted = false
    @State private var createdOrderId: Int? = nil // ✅ To store order ID after creation

    // ✅ Calculate total cost
    private var totalCost: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
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
                    Text(deliveryMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                Divider()

                HStack {
                    Text("Payment")
                        .font(.subheadline)
                    Spacer()
                    Text(paymentMethod)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                Divider()

                HStack {
                    Text("Total Cost")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "$%.2f", totalCost))
                        .fontWeight(.bold)
                }

                Divider()

                Text("By placing an order you agree to our Terms And Conditions")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)

                Button(action: {
                    createOrder(with: cartId)
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
        .fullScreenCover(isPresented: $showOrderAccepted) {
            OrderAcceptedView()
        }
    }

    // ✅ Create order then update it
    private func createOrder(with cartId: Int) {
        guard let userId = signInService.userId else {
            print("❌ User ID not found")
            return
        }

        print("🛒 Creating order for cart ID: \(cartId), user ID: \(userId), total: \(totalCost)")

        OrderService.shared.createOrder(cartId: cartId, userId: userId, totalPrice: totalCost) { result in
            switch result {
            case .success(let orderId):
                print("✅ Order placed with ID:", orderId)
                self.createdOrderId = orderId
                updateOrder(orderId: orderId)
                updateCartStatus(cartId: cartId, userId: userId) // ✅ Update cart status after order
            case .failure(let error):
                print("❌ Failed to place order:", error.localizedDescription)
            }
        }
    }

    // ✅ Update order after creation
    private func updateOrder(orderId: Int) {
        OrderService.shared.updateOrder(orderId: orderId, status: "BILLED", totalPrice: totalCost) { result in
            switch result {
            case .success:
                print("✅ Order updated successfully")
            case .failure(let error):
                print("❌ Failed to update order:", error.localizedDescription)
            }
        }
    }

    // ✅ Update cart status to PAYMENT_PROGRESS
    private func updateCartStatus(cartId: Int, userId: Int) {
        print("📦 Updating cart \(cartId) status to PAYMENT_PROGRESS")
        CartService.shared.updateCartStatus(cartId: cartId, status: "BILLED", userId: userId) { result in
            switch result {
            case .success:
                print("✅ Cart status updated")
                DispatchQueue.main.async {
                    showOrderAccepted = true
                }
            case .failure(let error):
                print("❌ Failed to update cart status:", error.localizedDescription)
            }
        }
    }
}
