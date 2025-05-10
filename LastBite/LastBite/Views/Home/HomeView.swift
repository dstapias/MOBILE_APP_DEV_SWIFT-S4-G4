import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @StateObject private var controller: HomeController
    @State private var searchText = ""

    init() {
        let storeRepository = APIStoreRepository()
        let orderRepository = APIOrderRepository()
        let signInService = SignInUserService.shared
        let locationManagerInstance = LocationManager()

        let homeController = HomeController(
            signInService: signInService,
            locationManager: locationManagerInstance,
            storeRepository: storeRepository,
            orderRepository: orderRepository
        )

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

                    if !controller.ownedStores.isEmpty {
                        CategorySectionView(title: "Owned Stores", items: controller.ownedStores)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        controller.refreshNearbyStoresManually()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                            Text("Update Location")
                        }
                        .font(.footnote.bold())
                        .foregroundColor(.green)
                    }
                }
            }
            .onAppear {
                print("🏠 HomeView Appeared. Triggering loadInitialData.")
                controller.loadInitialData()
            }
            .onReceive(networkMonitor.$isConnected) { isOn in
                if isOn {
                    controller.loadInitialData()
                }
            }
            .animation(.default, value: controller.storeItems)
            .animation(.default, value: controller.nearbyStores)
            .animation(.default, value: controller.ownedStores)
            .animation(.default, value: controller.forYouItems)
            .animation(.default, value: controller.activeOrders)
            .animation(.default, value: controller.isLoading)
            .animation(.default, value: controller.errorMessage)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

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

// --- Preview ---
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSignInService = SignInUserService.shared
        HomeView()
            .environmentObject(mockSignInService)
    }
}
