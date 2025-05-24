import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @StateObject private var controller: HomeController    // 1️⃣ Decláralo aquí
    @StateObject private var storeController: StoreController
    @State private var searchText = ""
    @State private var navigateToCreateStore = false


    init(controller: HomeController, networkMonitor: NetworkMonitor, signInService: SignInUserService) {
        let apiStoreRepository = APIStoreRepository()
        let localStoreRepository = LocalStoreRepository()
        let orderRepository = APIOrderRepository()
        let signInService = signInService
            let locManager = LocationManager()
            self._locationManager = StateObject(wrappedValue: locManager)
        let hybridStoreRepository = HybridStoreRepository(
            apiRepository: apiStoreRepository,
            localRepository: localStoreRepository,
            networkMonitor: networkMonitor, // Usando la instancia obtenida
            firebaseService: FirebaseService.shared
        )
        let storeCtrl = StoreController(
                    storeRepository: hybridStoreRepository,
                    networkMonitor: networkMonitor
        )
        
        let homeController = controller
        // 3️⃣ Así inicializas el @StateObject
        self._storeController = StateObject(wrappedValue: storeCtrl)
        self._controller = StateObject(wrappedValue: homeController)
        print("🏠 HomeView initialized and injected Store & Order Repositories into HomeController.")
        print("🏠 HomeView init: HomeController instance (self.controller) = \(Unmanaged.passUnretained(homeController).toOpaque())")

    }

    var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection // Usará signInService del entorno
                        searchField

                        loadingAndErrorSection // Vista computada para carga y error

                        ordersSection // Tu vista computada/subvista para órdenes

                        storeCategoriesAndSyncSection // Nueva vista computada para categorías y botón de sync
                    }
                    .padding(.vertical)
                }
                .navigationDestination(isPresented: $navigateToCreateStore) {
                  CreateStoreView(
                    controller: storeController,
                    homeController: controller,
                    onDismissAfterCreate: {
                      controller.loadInitialData()
                    }
                  )
                }
                .navigationTitle("Shop")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu{
                            Button {
                                controller.refreshNearbyStoresManually()
                            } label: {
                                Label("Update Location", systemImage: "location.circle.fill")
                            }
                            
                            Button {
                                navigateToCreateStore = true
                            } label: {
                                Label("Create Store", systemImage: "building.2.crop.circle")
                            }
                        }label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .onAppear {
                    print("🏠 HomeView Appeared. Triggering loadInitialData.")
                        print("🏠 HomeView .onAppear: Connected. Attempting sync.")
                        Task { await controller.synchronizeAllPendingData()
                            controller.loadInitialData()

                        }

                    
                }
                .onReceive(networkMonitor.$isConnected) { isConnected in
                    print("🏠 HomeView .onReceive: Network status is \(isConnected ? "Online" : "Offline")")
                        print("🏠 HomeView: Network reconnected. Triggering sync.")
                        Task { await controller.synchronizeAllPendingData()
                            controller.loadInitialData()
                        }
                        // Considera si necesitas llamar a loadInitialData aquí también,
                        // o si synchronizeAllPendingData ya refresca los datos necesarios.
                        // Si sync actualiza datos, y loadInitialData en controller también, podría ser redundante.
                        // controller.loadInitialData()

                }
                // Es mejor aplicar animaciones más granularmente si es posible.
                // Por ahora, las dejo para estados globales.
                .animation(.default, value: controller.isLoading)
                .animation(.default, value: controller.errorMessage)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // MARK: - Subvistas Computadas para Mejorar Claridad y Rendimiento del Compilador

        private var loadingAndErrorSection: some View {
            Group { // Group puede ayudar al compilador con múltiples condicionales
                if controller.isLoading {
                    ProgressView("Loading...")
                }

                if let error = controller.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .transition(.opacity) // Añadir transición para aparición/desaparición suave
                }
            }
        }

        @ViewBuilder
        private var storeCategoriesAndSyncSection: some View {
            // Las secciones de categorías
            if !controller.forYouItems.isEmpty {
                CategorySectionView(title: "Top Stores", items: controller.forYouItems, homeController: controller, networkMonitor: networkMonitor)
                    .animation(.default, value: controller.forYouItems) // Animar esta sección específica
            }

            if !controller.storeItems.isEmpty {
                CategorySectionView(title: "Stores", items: controller.storeItems, homeController: controller, networkMonitor: networkMonitor)
                    .animation(.default, value: controller.storeItems)
            }

            if !controller.nearbyStores.isEmpty {
                CategorySectionView(title: "Nearby Stores", items: controller.nearbyStores, homeController: controller, networkMonitor: networkMonitor)
                    .animation(.default, value: controller.nearbyStores)
            }

            if !controller.ownedStores.isEmpty {
                CategorySectionView(title: "Owned Stores", items: controller.ownedStores, homeController: controller, networkMonitor: networkMonitor)
                    .animation(.default, value: controller.ownedStores)
            }
            
            // Botón de Sincronización y mensaje offline
            // Usa la instancia de networkMonitor del entorno de HomeView
        }

        // --- Tus Subvistas Existentes (o propiedades computadas) ---
        // Asegúrate de que usen @EnvironmentObject si necesitan signInService o networkMonitor directamente.

    private var headerSection: some View {
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
