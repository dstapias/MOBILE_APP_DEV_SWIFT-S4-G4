import SwiftUI
import SDWebImageSwiftUI // Asegúrate de tener esta dependencia si usas WebImage

struct CartView: View {
    // 1. El controlador gestiona el estado. @StateObject lo mantiene vivo.
    @StateObject private var controller: CartController

    // 2. El servicio de usuario se usa SOLO para inicializar el controller.
    //    (Asegúrate que esté en el environment de la vista que crea CartView)
    //    @EnvironmentObject var signInService: SignInUserService // No se necesita aquí directamente

    // 3. Estado local SOLO para controlar si se muestra el sheet de checkout.
    @State private var showCheckout = false

    // 4. Inicializador que recibe las dependencias para el Controller.
    //    Este se usa donde creas CartView (ej. en tu TabView).
    init(signInService: SignInUserService) {
        // Crea la instancia del controller aquí, inyectando las dependencias.
        // Si necesitas inyectar servicios específicos (no singletons), hazlo aquí.
        _controller = StateObject(wrappedValue: CartController(signInService: signInService))
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Encabezado ---
                HStack {
                    Text("My Cart")
                        .font(.headline)
                    Spacer()
                    // Indicador de carga global (lee del controller)
                    if controller.isLoading {
                        ProgressView()
                            .padding(.trailing)
                    }
                }
                .padding()

                Divider()

                // --- Mensaje de Error Global (lee del controller) ---
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .transition(.opacity) // Animación opcional
                }


                // --- Lista de Productos ---
                ScrollView {
                    VStack(spacing: 0) {
                        // Mensaje de carrito vacío (condiciones leídas del controller)
                        if !controller.isLoading && controller.cartItems.isEmpty && controller.errorMessage == nil {
                            Text("Your cart is empty.")
                                .foregroundColor(.gray)
                                .padding(.top, 50) // Un poco de espacio
                        } else {
                            // Itera sobre los items publicados por el controller
                            // Asegúrate que CartItem sea Identifiable (por 'id' o 'productId')
                            // y que 'quantity' sea 'var' si usas $item
                            ForEach($controller.cartItems) { $item in // Usando binding
                                CartRowView(
                                    item: $item, // Pasa el binding
                                    removeAction: {
                                        // Llama directamente al controller
                                        controller.removeItemFromCart(productId: item.productId)
                                    },
                                    updateQuantity: { newQuantity in
                                        // Llama directamente al controller
                                        controller.updateCartQuantity(productId: item.productId, newQuantity: newQuantity)
                                    }
                                )
                                Divider().padding(.leading)
                            }
                        }
                    }
                } // Fin ScrollView

                // --- Botón de Checkout ---
                // Estado deshabilitado basado en el controller
                let isCheckoutDisabled = controller.cartItems.isEmpty || controller.activeCartId == nil || controller.isLoading

                Button(action: {
                    // Solo activa el estado local para mostrar el sheet
                    showCheckout = true
                }) {
                    // El texto podría cambiar si está deshabilitado, o solo el color/opacidad
                    Text("Go to Checkout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        // Color basado en si está habilitado (lee del controller indirectamente)
                        .background(isCheckoutDisabled ? Color.gray : Color.green)
                        .cornerRadius(8)
                }
                .padding()
                // Deshabilitar basado en el estado del controller
                .disabled(isCheckoutDisabled)
                // --- Presentación del Sheet de Checkout ---
                .sheet(isPresented: $showCheckout) {
                    // Prepara y presenta CheckoutView
                    prepareAndPresentCheckoutView()
                }

            } // Fin VStack principal
            .navigationBarHidden(true) // Opcional: decide si realmente necesitas ocultarla
            .animation(.default, value: controller.cartItems) // Anima cambios en la lista
            .animation(.default, value: controller.isLoading) // Anima aparición/desaparición del loader
            .animation(.default, value: controller.errorMessage) // Anima aparición/desaparición del error
            // --- Carga inicial de datos ---
            .onAppear {
                // Llama al método del controller para cargar todo
                controller.loadCartData()
            }
        } // Fin NavigationStack
    } // Fin body

    /// Función helper para mantener limpio el cuerpo del sheet
    @ViewBuilder
    private func prepareAndPresentCheckoutView() -> some View {
        // 1. Intenta preparar el CheckoutController usando el CartController
        if let checkoutController = controller.prepareCheckoutController() {
            // 2. Si tiene éxito, presenta CheckoutView con el controller preparado
            NavigationStack { // Opcional: Para tener barra de navegación dentro del sheet
                CheckoutView(controller: checkoutController)
                // Si CheckoutView necesita otros @EnvironmentObject, asegúrate que estén disponibles aquí.
                // .environmentObject(someOtherService)
            }
        } else {
            // 3. Si falla (ej. carrito vacío), muestra un mensaje dentro del sheet.
            //    El errorMessage ya debería estar puesto por prepareCheckoutController.
            VStack {
                Spacer()
                Text(controller.errorMessage ?? "Cannot proceed to checkout.")
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

// --- Vista de Fila (CartRowView) ---
// Asegúrate que sea compatible con cómo iteras (con o sin Binding)
// Este ejemplo asume que sigue usando @Binding
struct CartRowView: View {
    @Binding var item: CartItem
    var removeAction: () -> Void
    var updateQuantity: (Int) -> Void

    // El cuerpo de CartRowView no necesita cambios respecto a tu versión anterior
    // ... (tu implementación de HStack con WebImage, Text, Stepper/Buttons, etc.) ...
    var body: some View {
       HStack(alignment: .center, spacing: 8) {
           WebImage(url: URL(string: item.imageUrl)) // Ejemplo
               .resizable().scaledToFill().frame(width: 50, height: 50).cornerRadius(8).padding(.leading)
           VStack(alignment: .leading) { Text(item.name); Text(item.detail).font(.caption).foregroundColor(.gray) }
           Spacer()
           HStack {
               Button { if item.quantity > 1 { updateQuantity(item.quantity - 1) } else { /* Opcional: llamar removeAction si baja a 0 */ } } label: { Image(systemName: "minus.circle").foregroundColor(.green) }
               Text("\(item.quantity)").frame(minWidth: 20)
               Button { updateQuantity(item.quantity + 1) } label: { Image(systemName: "plus.circle").foregroundColor(.green) }
           }
           Text(String(format: "$%.2f", item.price * Double(item.quantity))).frame(width: 80, alignment: .trailing)
           Button(action: removeAction) { Image(systemName: "xmark").foregroundColor(.gray) }.padding(.trailing)
       }
       .padding(.vertical, 8)
   }
}


