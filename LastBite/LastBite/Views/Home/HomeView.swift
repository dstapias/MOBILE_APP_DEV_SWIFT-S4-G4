import SwiftUI
import SDWebImageSwiftUI // Si la usas

struct HomeView: View {
    // Dependencias del entorno y localización
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var locationManager = LocationManager() // Se mantiene para obtener ubicación

    // 1. Usa StateObject para el HomeController
    @StateObject private var controller: HomeController

    // Estado local solo para la UI (texto de búsqueda)
    @State private var searchText = ""

    // 2. Inicializador que crea el HomeController inyectando dependencias
    init() {
        // Crea el HomeController aquí, pasándole las dependencias necesarias.
        // Asume que SignInUserService.shared y los otros servicios son accesibles.
        // Si locationManager necesita ser inyectado explícitamente, ajusta el init.
        let homeController = HomeController(
            signInService: SignInUserService.shared, // Usa el singleton o inyectado
            locationManager: LocationManager() // Crea una instancia o pasa la @StateObject
                                               // Pasar @StateObject directamente es complejo,
                                               // es más fácil si HomeController crea/recibe LocationManager
                                               // O si LocationManager es un Singleton/EnvironmentObject
        )
        // Alternativa: Si LocationManager es un EnvObj:
        // init(signInService: SignInUserService, locationManager: LocationManager) {
        //    _controller = StateObject(wrappedValue: HomeController(signInService: signInService, locationManager: locationManager))
        // }
        // Por ahora, asumimos que HomeController puede instanciar/obtener LocationManager si lo necesita
        // o que el locationManager local es suficiente para pasar datos.

        _controller = StateObject(wrappedValue: homeController)
        print("🏠 HomeView initialized and owns HomeController.")
    }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 3. Header sigue leyendo directamente del servicio global
                    headerSection

                    // 4. SearchField sigue usando el @State local
                    searchField
                        // Podrías conectar la búsqueda al controller:
                        // .onChange(of: searchText) { controller.search($0) }

                    // 5. Muestra indicador de carga y errores del controller
                    if controller.isLoading {
                        ProgressView("Loading...")
                    }
                    if let error = controller.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // 6. Sección de órdenes lee del controller
                    ordersSection

                    // 7. Secciones de categorías leen del controller
                    //    Asegúrate que CategoryItemData sea Equatable para la animación
                    if !controller.forYouItems.isEmpty {
                        CategorySectionView(title: "For you", items: controller.forYouItems)
                    }

                    if !controller.storeItems.isEmpty {
                        CategorySectionView(title: "Stores", items: controller.storeItems)
                    }

                    if !controller.nearbyStores.isEmpty {
                        CategorySectionView(title: "Nearby Stores", items: controller.nearbyStores)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .onAppear {
                // 8. Llama al método de carga del controller
                print("🏠 HomeView Appeared. Triggering loadInitialData.")
                controller.loadInitialData()
                // Si necesitas pedir permiso de ubicación al aparecer:
                // locationManager.requestPermission()
            }
            // 9. .onChange ya no es necesario aquí si el controller observa al locationManager internamente
            //    (como hicimos en el HomeController refactorizado)
            // .onChange(of: locationManager.lastLocation) { ... }

            // 10. Animaciones (asegúrate que los modelos sean Equatable)
            .animation(.default, value: controller.storeItems)
            .animation(.default, value: controller.nearbyStores)
            .animation(.default, value: controller.forYouItems)
            .animation(.default, value: controller.activeOrders)
            .animation(.default, value: controller.isLoading)
            .animation(.default, value: controller.errorMessage)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // --- Sub-Vistas ---

    private var headerSection: some View {
        // Sin cambios, lee del servicio global
        Group {
            if let userId = signInService.userId, userId != -1 {
                Text("Logged in as User ID: \(userId)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            } else {
                Text("Not logged in")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
        }
    }

    private var searchField: some View {
         // Sin cambios, usa @State local
        TextField("Search store", text: $searchText)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }

    private var ordersSection: some View {
        Group {
            // Lee activeOrders del controller
            if !controller.activeOrders.isEmpty {
                 // Asegúrate que Order sea Identifiable y Equatable
                ForEach(controller.activeOrders) { order in
                    OrderStatusView(
                        statusMessage: "Pedido #\(order.order_id) en progreso...",
                        buttonTitle: "Ya lo recibí",
                        imageName: "orderClock"
                    ) {
                        // 11. Llama al método del controller directamente
                        controller.receiveOrder(orderId: order.order_id)
                    }
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            } else {
                 // Muestra banner si no hay órdenes y no está cargando
                if !controller.isLoading { // O usa un isLoadingOrders específico
                    Image("fresh_vegetables_banner")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
        }
    }

    // 12. Elimina las funciones fetchStores, fetchNearbyStores, etc. de aquí
}

// --- Preview ---
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Crea mocks o usa singletons para la preview
        let mockSignInService = SignInUserService.shared // O un mock
        // let mockLocationManager = LocationManager() // Si HomeController lo necesita

        HomeView() // El init ahora no necesita params si HomeController usa Singletons
            // Si HomeView.init requiere params, provéelos aquí:
            // HomeView(signInService: mockSignInService)
            .environmentObject(mockSignInService) // Asegúrate que esté en el environment
            // .environmentObject(mockLocationManager) // Si es necesario
    }
}

// --- Vistas y Modelos Auxiliares ---
// Asegúrate que CategorySectionView, OrderStatusView, LocationManager,
// y los modelos (Order, Store, CategoryItemData) estén definidos y sean
// Identifiable/Equatable según sea necesario.
