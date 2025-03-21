//
//  CartService.swift
//  LastBite
//
//  Created by David Santiago on 20/03/25.
//
import Foundation

class CartService {
    static let shared = CartService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct Cart: Codable {
        let cart_id: Int
        let creation_date: String
        let status: String
        let status_date: String
        let user_id: Int
    }

    // ✅ Fetch Active Cart for a User
    func fetchActiveCart(for userID: Int, completion: @escaping (Result<Cart, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/carts/user/\(userID)/active") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching active cart:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(Cart.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("❌ JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
}

