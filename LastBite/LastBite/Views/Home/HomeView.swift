import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var signInService: SignInUserService
    @StateObject private var locationManager = LocationManager() // ✅ Location Manager
    @State private var searchText = ""
    @State private var storeItems: [CategoryItemData] = []
    @State private var nearbyStores: [CategoryItemData] = []
    @State private var forYouItems: [CategoryItemData] = []
    
    @State private var isOrderActive: Bool = true


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

                    // Banner
                    if isOrderActive {
                                            OrderStatusView(
                                                statusMessage: "Tu pedido está en progreso...",
                                                buttonTitle: "Ya lo recogí",
                                                imageName: "imageen"
                                            ) {
                                                isOrderActive = false
                                            }
                                            .cornerRadius(8)                .padding(.horizontal)
                                        }
                    else {
                        Image("fresh_vegetables_banner")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    // Sección
                    if !forYouItems.isEmpty {
                        CategorySectionView(title: "For you", items: forYouItems)
                    }
                    // Sección Supermarkets
                    if !storeItems.isEmpty {
                        CategorySectionView(title: "Stores", items: storeItems)
                    }

                    // Sección Nearby Stores
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
            }
            .onChange(of: locationManager.latitude) { _ in
                fetchNearbyStores()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // ✅ Fetch all stores
    private func fetchStores() {
        StoreService.shared.fetchStores { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    storeItems = stores.map { store in
                        CategoryItemData(
                            title: store.name,
                            imageName: store.logo,
                            store: store
                        )
                    }
                case .failure(let error):
                    print("❌ Failed to fetch stores:", error.localizedDescription)
                }
            }
        }
    }

    // ✅ Fetch nearby stores **after location updates**
    private func fetchNearbyStores() {
        guard let lat = locationManager.latitude, let lon = locationManager.longitude else {
            print("❌ Location not available yet")
            return
        }
        print("✅ Fetching nearby stores at Latitude: \(lat), Longitude: \(lon)") // ✅ Debugging
        StoreService.shared.fetchNearbyStores(latitude: lat, longitude: lon) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    print("✅ Nearby stores fetched: \(stores.count)")
                    nearbyStores = stores.map { store in
                        CategoryItemData(
                            title: store.name,
                            imageName: store.logo,
                            store: store
                        )
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
                       print("✅ Top stores fetched: \(stores.count)")
                       forYouItems = stores.map { store in
                           CategoryItemData(
                               title: store.name,
                               imageName: store.logo,
                               store: store
                           )
                       }
                   case .failure(let error):
                       print("❌ Failed to fetch top stores:", error.localizedDescription)
                   }
               }
           }
       }
    
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
