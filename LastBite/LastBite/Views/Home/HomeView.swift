import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var storeItems: [CategoryItemData] = []
    @State private var nearbyStores: [CategoryItemData] = []
    @State private var forYouItems: [CategoryItemData] = []
    @State private var activeOrders: [OrderService.Order] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let userId = signInService.userId {
                        Text("Logged in as: \(userId)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    } else {
                        Text("Not logged in")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }

                    TextField("Search store", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Banner u Órdenes activas
                    if !activeOrders.isEmpty {
                        ForEach(activeOrders, id: \.order_id) { order in
                            OrderStatusView(
                                statusMessage: "Pedido #\(order.order_id) en progreso...",
                                buttonTitle: "Ya lo recibí",
                                imageName: "orderClock"
                            ) {
                                receiveOrder(orderId: order.order_id)
                            }
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    } else {
                        Image("fresh_vegetables_banner")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    if !forYouItems.isEmpty {
                        CategorySectionView(title: "For you", items: forYouItems)
                    }

                    if !storeItems.isEmpty {
                        CategorySectionView(title: "Stores", items: storeItems)
                    }

                    if !nearbyStores.isEmpty {
                        CategorySectionView(title: "Nearby Stores", items: nearbyStores)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .onAppear {
                fetchStores()
                fetchTopStores()
                fetchNotReceivedOrders()
            }
            .onChange(of: locationManager.latitude) { _ in
                fetchNearbyStores()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fetchStores() {
        StoreService.shared.fetchStores { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    storeItems = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                case .failure(let error):
                    print("❌ Failed to fetch stores:", error.localizedDescription)
                }
            }
        }
    }

    private func fetchNearbyStores() {
        guard let lat = locationManager.latitude, let lon = locationManager.longitude else {
            print("❌ Location not available yet")
            return
        }

        StoreService.shared.fetchNearbyStores(latitude: lat, longitude: lon) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    nearbyStores = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                case .failure(let error):
                    print("❌ Failed to fetch nearby stores:", error.localizedDescription)
                }
            }
        }
    }

    private func fetchTopStores() {
        StoreService.shared.fetchTopStores { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    forYouItems = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo, store: $0)
                    }
                case .failure(let error):
                    print("❌ Failed to fetch top stores:", error.localizedDescription)
                }
            }
        }
    }

    private func fetchNotReceivedOrders() {
        guard let userId = signInService.userId else {
            print("❌ No user ID available")
            return
        }

        OrderService.shared.fetchNotReceivedOrdersForUser(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let orders):
                    self.activeOrders = orders
                case .failure(let error):
                    print("❌ Failed to fetch not received orders:", error.localizedDescription)
                }
            }
        }
    }

    private func receiveOrder(orderId: Int) {
        print("📦 Marking order \(orderId) as received (enabled = 1)...")

        OrderService.shared.receiveOrder(orderId: orderId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.activeOrders.removeAll { $0.order_id == orderId }
                    print("✅ Order \(orderId) marked as received")
                case .failure(let error):
                    print("❌ Failed to mark order as received:", error.localizedDescription)
                }
            }
        }
    }

}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SignInUserService.shared)
    }
}
