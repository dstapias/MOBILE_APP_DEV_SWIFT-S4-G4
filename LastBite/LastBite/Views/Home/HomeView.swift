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
            // 1. Crea las instancias de AMBOS repositorios concretos
            let storeRepository = APIStoreRepository()
            let orderRepository = APIOrderRepository()

            // (Opcional) Obtener otras dependencias
            let signInService = SignInUserService.shared
            let locationManagerInstance = LocationManager() // O usa singleton/inyectado

            // 2. Crea el HomeController pasándole AMBOS repositorios
            let homeController = HomeController(
                signInService: signInService,
                locationManager: locationManagerInstance,
                storeRepository: storeRepository,   // <- Inyecta Store Repo
                orderRepository: orderRepository    // <- Inyecta Order Repo
            )

            // 3. Asigna al StateObject wrapper
            self._controller = StateObject(wrappedValue: homeController)
            print("🏠 HomeView initialized and injected Store & Order Repositories into HomeController.")
        }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection

                    searchField
                    if controller.isLoading {
                        ProgressView("Loading...")
                    }
                    if let error = controller.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    ordersSection

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
                print("🏠 HomeView Appeared. Triggering loadInitialData.")
                controller.loadInitialData()

            }
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
        TextField("Search store", text: $searchText)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }

    private var ordersSection: some View {
        Group {
            if !controller.activeOrders.isEmpty {
                ForEach(controller.activeOrders) { order in
                    OrderStatusView(
                        statusMessage: "Pedido #\(order.order_id) en progreso...",
                        buttonTitle: "Ya lo recibí",
                        imageName: "orderClock"
                    ) {
                        Task {
                            await controller.receiveOrder(orderId: order.order_id)
                        }
                    }
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            } else {
                if !controller.isLoading {
                    Image("fresh_vegetables_banner")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// --- Preview ---
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSignInService = SignInUserService.shared

        HomeView()
            .environmentObject(mockSignInService)
    }
}
