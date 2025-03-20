import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @StateObject private var locationManager = LocationManager() // ✅ Location Manager
    @State private var searchText = ""
    @State private var storeItems: [CategoryItemData] = []
    @State private var nearbyStores: [CategoryItemData] = []

    let forYouItems = [
        CategoryItemData(title: "Hornitos", imageName: "hornitos"),
        CategoryItemData(title: "Cascabel", imageName: "cascabel")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    TextField("Search store", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Banner
                    Image("fresh_vegetables_banner")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Sección Bakery
                    CategorySectionView(title: "For you", items: forYouItems)

                    // Sección Supermarkets
                    CategorySectionView(title: "Stores", items: storeItems)

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
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
