//
//  CartProductService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class CartProductService {
    static let shared = CartProductService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct CartProduct: Codable {
        let cart_id: Int
        let product_id: Int
        let quantity: Int
    }
    
    struct DetailedCartProduct: Codable {
          let product_id: Int
          let name: String
          let detail: String
          let quantity: Int
          let unit_price: Double
          let image: String
      }
    
    func fetchDetailedCartProducts(for cartID: Int, completion: @escaping (Result<[DetailedCartProduct], Error>) -> Void) {
            guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/detailed") else {
                completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("❌ Error fetching detailed cart products:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    print("❌ Error: No Data Received")
                    completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode([DetailedCartProduct].self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("❌ JSON Decoding Error:", error.localizedDescription)
                    completion(.failure(error))
                }
            }.resume()
        }
    
    // ✅ Fetch Products in a Cart
    func fetchCartProducts(for cartID: Int, completion: @escaping (Result<[CartProduct], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching cart products:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([CartProduct].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("❌ JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
    
    // ✅ Add Product to Cart
    func addProductToCart(cartID: Int, productID: Int, quantity: Int = 1, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/cart_products") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        let body: [String: Any] = [
            "cart_id": cartID,
            "product_id": productID,
            "quantity": quantity
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error adding product to cart:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("❌ Server error. Status code:", statusCode)
                completion(.failure(NSError(domain: "Server Error", code: statusCode, userInfo: nil)))
                return
            }

            print("✅ Product added to cart successfully.")
            completion(.success(()))
        }.resume()
    }
    
    func updateProductQuantity(cartID: Int, productID: Int, quantity: Int, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/product/\(productID)") else {
                completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "quantity": quantity
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("❌ Error updating product quantity:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("❌ Server error. Status code:", statusCode)
                    completion(.failure(NSError(domain: "Server Error", code: statusCode, userInfo: nil)))
                    return
                }

                print("✅ Product quantity updated successfully.")
                completion(.success(()))
            }.resume()
        }
    func removeProductFromCart(cartID: Int, productID: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/product/\(productID)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Error removing product from cart:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("❌ Server error. Status code:", statusCode)
                completion(.failure(NSError(domain: "Server Error", code: statusCode, userInfo: nil)))
                return
            }

            print("✅ Product successfully removed from cart.")
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }


}
    
