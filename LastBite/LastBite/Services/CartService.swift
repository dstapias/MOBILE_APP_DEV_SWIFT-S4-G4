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
    
    func updateCartStatus(cartId: Int, status: String, userId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let url = URL(string: "\(Constants.baseURL)/carts/\(cartId)/status") else {
                completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
                return
            }

            let body: [String: Any] = [
                "status": status,
                "user_id": userId
            ]

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("❌ Error updating cart status:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("❌ Server error. Status code:", statusCode)
                    completion(.failure(NSError(domain: "Server Error", code: statusCode, userInfo: nil)))
                    return
                }

                print("✅ Cart status updated to \(status)")
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }.resume()
        }
    
}


