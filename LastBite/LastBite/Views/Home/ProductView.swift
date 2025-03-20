import SwiftUI
import SDWebImageSwiftUI

struct ProductView: View {
    let store: StoreService.Store // ✅ Store details
    @State private var products: [ProductService.Product] = [] // ✅ Store products
    @State private var tags: [Int: [TagService.Tag]] = [:] // ✅ Stores tags by product_id
    @State private var searchText = "" // ✅ Search bar

    var body: some View {
        VStack {
            // 🔍 Search Bar
            TextField("Search Products", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // 🛒 Products Grid
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Food") // ✅ Section title
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(products.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }, id: \.product_id) { product in
                            ProductCard(product: product, tags: tags[product.product_id] ?? [])
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("")
        .onAppear {
            fetchProducts()
        }
    }

    // ✅ Fetch products and then fetch their tags
    private func fetchProducts() {
        ProductService.shared.fetchProducts(for: store.store_id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedProducts):
                    products = fetchedProducts
                    for product in fetchedProducts {
                        fetchTags(for: product.product_id)
                    }
                case .failure(let error):
                    print("❌ Failed to fetch products:", error.localizedDescription)
                }
            }
        }
    }

    // ✅ Fetch Tags for a Product
    private func fetchTags(for productID: Int) {
        TagService.shared.fetchTags(for: productID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedTags):
                    tags[productID] = fetchedTags
                case .failure(let error):
                    print("❌ Failed to fetch tags:", error.localizedDescription)
                }
            }
        }
    }
}

// ✅ Product Card Component with Tags
struct ProductCard: View {
    let product: ProductService.Product
    let tags: [TagService.Tag] // ✅ Tags for this product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WebImage(url: URL(string: product.image))
                .resizable()
                .indicator(.activity)
                .scaledToFit()
                .frame(height: 100)
                .cornerRadius(8)

            Text(product.name)
                .font(.headline)
                .foregroundColor(.black)

            // ✅ Display tags as comma-separated list
            Text(tags.map { $0.value }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)

            Text("$\(String(format: "%.2f", product.unit_price))")
                .font(.headline)
                .foregroundColor(.green)

            // ✅ Square "Add" button with rounded corners
            HStack {
                Spacer()
                Button(action: {
                    print("Added \(product.name) to cart")
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.green)
                        .cornerRadius(8) // ✅ Makes it a square with rounded edges
                }
            }
            .padding(.bottom, 40) // ✅ Moves the button up slightly
        }
        .padding()
        .frame(width: 160, height: 220)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView(store: StoreService.Store(
            store_id: 1,
            name: "Example Store",
            address: "123 Street, City",
            latitude: 0.0,
            longitude: 0.0,
            logo: "https://example.com/logo.png",
            nit: "900123456-1"
        ))
    }
}
