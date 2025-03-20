//
//  ProductView.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProductView: View {
    let store: StoreService.Store // ✅ Store details
    @State private var products: [ProductService.Product] = [] // ✅ Store products

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 📸 Store Banner
                WebImage(url: URL(string: store.logo))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)

                // 🏪 Store Name & Address
                VStack {
                    Text(store.name)
                        .font(.title)
                        .bold()
                    Text(store.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                // 📦 Products Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Products")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(products, id: \.product_id) { product in
                        HStack {
                            WebImage(url: URL(string: product.image))
                                .resizable()
                                .indicator(.activity)
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                Text(product.detail)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)

                                HStack {
                                    Text("$\(String(format: "%.2f", product.unit_price))") // ✅ Corrected price field
                                        .font(.subheadline)
                                        .foregroundColor(.green)

                                    Spacer()

                                    Text("⭐ \(product.score, specifier: "%.1f")")
                                        .font(.subheadline)
                                        .foregroundColor(.yellow)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Products")
        .onAppear {
            fetchProducts()
        }
    }

    // ✅ Fetch products from backend
    private func fetchProducts() {
        ProductService.shared.fetchProducts(for: store.store_id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedProducts):
                    products = fetchedProducts
                case .failure(let error):
                    print("Failed to fetch products:", error.localizedDescription)
                }
            }
        }
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
