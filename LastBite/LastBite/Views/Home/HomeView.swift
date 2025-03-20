import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var storeItems: [CategoryItemData] = [] // ✅ Store items from backend
    
    let forYouItems = [
        CategoryItemData(title: "Hornitos", imageName: "hornitos"),
        CategoryItemData(title: "Cascabel", imageName: "cascabel")
    ]
    
    let nearbyItems = [
        CategoryItemData(title: "KFC", imageName: "kfc"),
        CategoryItemData(title: "Fried Chicken", imageName: "chicken")
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
                    CategorySectionView(title: "Stores", items: storeItems) // ✅ Uses fetched stores
                    
                    // Sección Chicken
                    CategorySectionView(title: "Nearby Stores", items: nearbyItems)
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .onAppear(perform: fetchStores) // ✅ Fetch stores when view appears
        }
    }

    // ✅ Fetch stores from backend
    private func fetchStores() {
        StoreService.shared.fetchStores { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stores):
                    storeItems = stores.map {
                        CategoryItemData(title: $0.name, imageName: $0.logo) // ✅ Uses name & logo
                    }
                case .failure(let error):
                    print("Failed to fetch stores:", error.localizedDescription)
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
