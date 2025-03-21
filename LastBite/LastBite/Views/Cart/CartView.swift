import SwiftUI
import SDWebImageSwiftUI

struct CartItem: Identifiable {
    let id = UUID()
    let productId: Int
    let name: String
    let detail: String
    var quantity: Int
    let price: Double
    let imageUrl: String
}

struct CartView: View {
    @EnvironmentObject var signInService: SignInUserService
    @State private var cartItems: [CartItem] = [] // ✅ Holds products in the cart
    @State private var showCheckout = false
    @State private var activeCartId: Int? = nil // ✅ Store active cart ID

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Encabezado
                HStack {
                    Text("My Cart")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Lista de productos
                ScrollView {
                    VStack(spacing: 0) {
                        if cartItems.isEmpty {
                            Text("Your cart is empty.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(cartItems.indices, id: \.self) { index in
                                CartRowView(
                                    item: $cartItems[index],
                                    removeAction: {
                                        removeItemFromCart(productId: cartItems[index].productId)
                                    },
                                    updateQuantity: { newQuantity in
                                        updateCartQuantity(productID: cartItems[index].productId, newQuantity: newQuantity)
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Botón de Checkout
                Button(action: {
                    showCheckout = true
                }) {
                    Text("Go to Checkout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding()
                .sheet(isPresented: $showCheckout) {
                    NavigationStack {
                        CheckoutView(cartItems: cartItems)
                            .presentationDetents([.medium, .large]) // Opcional, iOS 16+
                    }
                }
            }
            .navigationBarHidden(true)  // Oculta la barra de navegación si quieres
            .onAppear {
                fetchActiveCart() // ✅ Fetch active cart when view appears
            }
        }
    }

    // ✅ Fetch the active cart for the user
    private func fetchActiveCart() {
        guard let userId = signInService.userId else {
            print("❌ No user ID found")
            return
        }

        CartService.shared.fetchActiveCart(for: userId) { result in
            switch result {
            case .success(let cart):
                DispatchQueue.main.async {
                    self.activeCartId = cart.cart_id
                    print("✅ Active Cart ID:", cart.cart_id)
                    fetchCartProducts() // ✅ Fetch cart products using stored activeCartId
                }
            case .failure(let error):
                print("❌ Failed to find active cart:", error.localizedDescription)
            }
        }
    }

    // ✅ Fetch products in the active cart
    private func fetchCartProducts() {
        guard let cartId = activeCartId else {
            print("❌ No active cart found")
            return
        }

        CartProductService.shared.fetchDetailedCartProducts(for: cartId) { result in
            switch result {
            case .success(let cartProducts):
                DispatchQueue.main.async {
                    self.cartItems = cartProducts.map { cartProduct in
                        CartItem(
                            productId: cartProduct.product_id,
                            name: cartProduct.name,
                            detail: cartProduct.detail,
                            quantity: cartProduct.quantity,
                            price: cartProduct.unit_price,
                            imageUrl: cartProduct.image
                        )
                    }
                    print("✅ Fetched \(cartProducts.count) products in the cart")
                }
            case .failure(let error):
                print("❌ Failed to fetch cart products:", error.localizedDescription)
            }
        }
    }

    // ✅ Remove product from cart
    private func removeItemFromCart(productId: Int) {
        guard let cartId = activeCartId else {
            print("❌ No active cart found")
            return
        }

        CartProductService.shared.removeProductFromCart(cartID: cartId, productID: productId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.cartItems.removeAll { $0.productId == productId }
                    print("✅ Product removed from cart")
                }
            case .failure(let error):
                print("❌ Failed to remove product:", error.localizedDescription)
            }
        }
    }

    // ✅ Update quantity in the backend
    private func updateCartQuantity(productID: Int, newQuantity: Int) {
        guard let cartId = activeCartId else {
            print("❌ No active cart found")
            return
        }

        CartProductService.shared.updateProductQuantity(cartID: cartId, productID: productID, quantity: newQuantity) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if let index = self.cartItems.firstIndex(where: { $0.productId == productID }) {
                        self.cartItems[index].quantity = newQuantity
                    }
                    print("✅ Cart updated successfully")
                }
            case .failure(let error):
                print("❌ Failed to update cart:", error.localizedDescription)
            }
        }
    }
}

// ✅ Updated CartRowView to accept quantity update function
struct CartRowView: View {
    @Binding var item: CartItem
    var removeAction: () -> Void
    var updateQuantity: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // ✅ Load Image from URL using SDWebImage
            WebImage(url: URL(string: item.imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .padding(.leading, 8)

            // ✅ Product Name & Description
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.detail)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            // ✅ Quantity Controls
            HStack(spacing: 8) {
                Button(action: {
                    if item.quantity > 1 {
                        let newQuantity = item.quantity - 1
                        updateQuantity(newQuantity)
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.green)
                        .font(.title2)
                }

                Text("\(item.quantity)")
                    .frame(width: 24)

                Button(action: {
                    let newQuantity = item.quantity + 1
                    updateQuantity(newQuantity)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }

            // ✅ Product Price (Multiplying by Quantity)
            Text(String(format: "$%.2f", item.price * Double(item.quantity))) // ✅ Shows total price
                .frame(width: 80, alignment: .trailing)

            // ✅ Remove Button
            Button(action: removeAction) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
    }
}

// ✅ Preview
struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(SignInUserService.shared) // ✅ Ensure environment object is injected
    }
}
