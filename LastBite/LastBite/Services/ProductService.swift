//
//  ProductService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class ProductService {
    static let shared = ProductService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct Product: Codable {
        let product_id: Int
        let name: String
        let detail: String
        let unit_price: Double // ✅ Matches JSON "unit_price"
        let image: String
        let score: Double
        let store_id: Int
        let product_type: String // ✅ Matches JSON "product_type"
    }

    // ✅ Fetch Products from Backend for a Store
    func fetchProducts(for storeID: Int, completion: @escaping (Result<[Product], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/products/store/\(storeID)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching products:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Product].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
}
