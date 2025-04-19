import SwiftUI
import SDWebImageSwiftUI

struct CartView: View {
    // 1. El controlador gestiona el estado. @StateObject lo mantiene vivo.
    @StateObject private var controller: CartController

    // 2. El servicio de usuario SOLO se necesita para el init del controller
    //    (O se accede vía singleton dentro del init).
    // @EnvironmentObject var signInService: SignInUserService

    // 3. Estado local SOLO para controlar si se muestra el sheet de checkout.
    @State private var showCheckout = false

    // 4. Inicializador CORRECTO que crea Controller e inyecta Repositorios
    init(signInService: SignInUserService) {
        let cartRepository = APICartRepository()
        let orderRepository = APIOrderRepository() // Necesario para prepareCheckoutController
        let cartController = CartController(
            signInService: signInService,
            cartRepository: cartRepository,
            orderRepository: orderRepository // Pasa el repo de órdenes
        )
        self._controller = StateObject(wrappedValue: cartController)
        print("🛒 CartView initialized and injected Repositories into CartController.")
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Encabezado ---
                HStack {
                    Text("My Cart").font(.headline)
                    Spacer()
                    if controller.isLoading { ProgressView().padding(.trailing) }
                }
                .padding()

                Divider()

                // --- Mensaje de Error Global ---
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red).font(.footnote)
                        .padding(.horizontal).padding(.bottom, 5)
                        .transition(.opacity)
                }

                // --- Lista de Productos ---
                ScrollView {
                    VStack(spacing: 0) {
                        // Mensaje de carrito vacío
                        if !controller.isLoading && controller.cartItems.isEmpty && controller.errorMessage == nil {
                            Text("Your cart is empty.")
                                .foregroundColor(.gray).padding(.top, 50)
                        } else {
                            // --- ForEach CORREGIDO ---
                            ForEach($controller.cartItems) { $item in // $item es Binding<CartItem>
                                CartRowView(
                                    item: $item, // OK pasar Binding a CartRowView
                                    removeAction: {
                                        // Usa .wrappedValue para acceder al CartItem real
                                        controller.removeItemFromCart(productId: $item.wrappedValue.productId)
                                    },
                                    updateQuantity: { newQuantity in
                                        // Usa .wrappedValue para acceder al CartItem real
                                        controller.updateCartQuantity(productId: $item.wrappedValue.productId, newQuantity: newQuantity)
                                    }
                                )
                                Divider().padding(.leading)
                            }
                            // --- FIN ForEach CORREGIDO ---
                        }
                    }
                } // Fin ScrollView

                // --- Botón de Checkout ---
                let isCheckoutDisabled = controller.cartItems.isEmpty || controller.activeCartId == nil || controller.isLoading

                Button(action: { showCheckout = true }) {
                    Text("Go to Checkout")
                        .fontWeight(.bold).foregroundColor(.white).padding()
                        .frame(maxWidth: .infinity)
                        .background(isCheckoutDisabled ? Color.gray : Color.green).cornerRadius(8)
                }
                .padding()
                .disabled(isCheckoutDisabled)
                 // Presenta CheckoutView como sheet
                .sheet(isPresented: $showCheckout) {
                    // Llama a la función helper que prepara y presenta
                    prepareAndPresentCheckoutView()
                }

            } // Fin VStack principal
            .navigationBarHidden(true) // Oculta barra de navegación si usas NavigationStack interno
            // Animaciones (requieren que CartItem sea Equatable)
            .animation(.default, value: controller.cartItems)
            .animation(.default, value: controller.isLoading)
            .animation(.default, value: controller.errorMessage)
            // Carga inicial de datos
            .onAppear {
                controller.loadCartData()
            }
        } // Fin NavigationStack
    } // Fin body

    /// Función helper para preparar y mostrar CheckoutView (CORREGIDA)
        @ViewBuilder
        private func prepareAndPresentCheckoutView() -> some View {
            // 1. Obtén los datos necesarios directamente del CartController
            //    Asegúrate de que el carrito esté activo y no esté vacío.
            if let cartId = controller.activeCartId, !controller.cartItems.isEmpty {
                // 2. Llama al inicializador correcto de CheckoutView, pasando los datos
                NavigationStack { // Opcional: Mantenlo si quieres una barra dentro del sheet
                    CheckoutView(
                        cartItems: controller.cartItems, // <- Pasa los items
                        cartId: cartId                  // <- Pasa el ID del carrito
                    )
                    // Si CheckoutView o su controller dependen de SignInUserService vía Environment,
                    // asegúrate de que esté disponible. Puedes añadirlo aquí o asegurar que
                    // esté en el environment de CartView.
                    // .environmentObject(SignInUserService.shared)
                }
            } else {
                // 3. Si no se puede ir al checkout, muestra un error
                //    El controller.errorMessage puede que ya tenga un mensaje útil.
                VStack {
                    Spacer()
                    Text(controller.errorMessage ?? "Cannot proceed to checkout. Cart is empty or inactive.")
                        .foregroundColor(.red)
                        .padding()
                    Button("Dismiss") {
                        showCheckout = false // Cierra el sheet
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
        }
} // Fin struct CartView

// MARK: - Vista de Fila (CartRowView)

struct CartRowView: View {
    @Binding var item: CartItem // Recibe el Binding
    var removeAction: () -> Void
    var updateQuantity: (Int) -> Void

    var body: some View {
       HStack(alignment: .center, spacing: 8) {
           // Usa la URL de la imagen del item
           WebImage(url: URL(string: item.imageUrl))
               .resizable().scaledToFill().frame(width: 50, height: 50).cornerRadius(8).padding(.leading)

           VStack(alignment: .leading) {
               Text(item.name) // Usa nombre del item
                   .font(.subheadline).fontWeight(.medium) // Ajusta fuente si es necesario
               Text(item.detail) // Usa detalle del item
                   .font(.caption).foregroundColor(.gray)
           }
           Spacer()

           // Stepper o botones +/- para cantidad
           HStack(spacing: 5) { // Menos espacio entre botones +/-
               Button {
                   // Llama a updateQuantity solo si es mayor a 1
                   if item.quantity > 1 { updateQuantity(item.quantity - 1) }
                   // Opcional: Si quieres que al llegar a 1 y presionar menos se elimine:
                   // else { removeAction() }
               } label: {
                   Image(systemName: "minus.circle.fill") // Relleno para mejor click
                       .foregroundColor(.green.opacity(item.quantity > 1 ? 1.0 : 0.5)) // Atenúa si es 1
               }
               .disabled(item.quantity <= 1) // Deshabilita si es 1

               Text("\(item.quantity)") // Muestra cantidad del item
                   .font(.body).frame(minWidth: 25, alignment: .center) // Ancho mínimo

               Button { updateQuantity(item.quantity + 1) } label: { // Llama a updateQuantity
                   Image(systemName: "plus.circle.fill") // Relleno
                       .foregroundColor(.green)
               }
           }
           .padding(.horizontal, 5) // Padding ligero alrededor de +/-/num

           // Precio total del item (precio unitario * cantidad)
           Text(String(format: "$%.2f", item.price * Double(item.quantity)))
               .font(.subheadline).fontWeight(.semibold) // Ajusta fuente
               .frame(width: 80, alignment: .trailing)

           // Botón para eliminar
           Button(action: removeAction) { // Llama a removeAction
               Image(systemName: "xmark.circle.fill") // Relleno y más grande
                   .foregroundColor(.gray.opacity(0.7)) // Color más suave
                   .font(.title3) // Un poco más grande
           }
           .padding(.trailing)

       } // Fin HStack principal
       .padding(.vertical, 8) // Padding vertical para cada fila
       // Añade un ID explícito si ForEach tiene problemas (aunque id derivado debería funcionar)
       // .id(item.id)
   }
}


// MARK: - Preview Provider

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        // Necesita el servicio en el entorno para el init
        CartView(signInService: SignInUserService.shared) // Pasa el servicio real o un mock
            .environmentObject(SignInUserService.shared) // Asegura que esté en el entorno
    }
}

// --- Asegúrate que existan ---
// class CartController: ObservableObject { ... }
// class CheckoutController: ObservableObject { ... } // El que se presenta en el sheet
// struct CartItem: Identifiable, Equatable { ... }
// struct DetailedCartProduct: Codable, Identifiable, Equatable { ... } // Usado en el mapeo del controller
// protocol CartRepository { ... }
// class APICartRepository: CartRepository { ... }
// protocol OrderRepository { ... }
// class APIOrderRepository: OrderRepository { ... }
// class SignInUserService: ObservableObject { ... }
// struct CheckoutView: View { init(controller: CheckoutController) ... } // Asegúrate que CheckoutView tenga este init
