//
//  CartProductService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class CartProductService {
    static let shared = CartProductService()
    private init() {}

    // --- Helpers (Reutilizados o copiados de OrderService) ---
    private func createJsonRequest(url: URL, method: String, bodyJson: [String: Any]? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = bodyJson {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                throw ServiceError.serializationError(error)
            }
        }
        return request
    }

    private func performRequest(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1)
            }
            print("📬 [\(request.httpMethod ?? "")] \(request.url?.absoluteString ?? "") -> Status: \(httpResponse.statusCode)")
            return (data, httpResponse)
        } catch {
            print("❌ Network Error for \(request.url?.absoluteString ?? ""): \(error)")
            throw ServiceError.requestFailed(error)
        }
    }
    // --- Fin Helpers ---


    // MARK: - Async Methods

    func fetchDetailedCartProductsAsync(for cartID: Int) async throws -> [DetailedCartProduct] {
        guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/detailed") else {
            throw ServiceError.invalidURL
        }
        let request = try createJsonRequest(url: url, method: "GET")
        let (data, httpResponse) = try await performRequest(request: request)

        guard httpResponse.statusCode == 200 else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            return try decoder.decode([DetailedCartProduct].self, from: data)
        } catch {
            print("❌ Decoding error fetching detailed cart products for cart \(cartID): \(error)")
            throw ServiceError.decodingError(error)
        }
    }

    func fetchCartProductsAsync(for cartID: Int) async throws -> [CartProduct] {
         guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)") else {
            throw ServiceError.invalidURL
        }
        let request = try createJsonRequest(url: url, method: "GET")
        let (data, httpResponse) = try await performRequest(request: request)

        guard httpResponse.statusCode == 200 else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CartProduct].self, from: data)
        } catch {
             print("❌ Decoding error fetching cart products for cart \(cartID): \(error)")
            throw ServiceError.decodingError(error)
        }
    }

    func addProductToCartAsync(cartID: Int, productID: Int, quantity: Int = 1) async throws {
         guard let url = URL(string: "\(Constants.baseURL)/cart_products") else {
            throw ServiceError.invalidURL
        }
        let body: [String: Any] = ["cart_id": cartID, "product_id": productID, "quantity": quantity]
        let request = try createJsonRequest(url: url, method: "POST", bodyJson: body)
        let (_, httpResponse) = try await performRequest(request: request)

        // POST para añadir suele devolver 200 OK (si actualiza) o 201 Created (si crea nuevo)
        guard (200...299).contains(httpResponse.statusCode) else {
             throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        print("✅ Product \(productID) added/updated in cart \(cartID).")
        // No devuelve nada (Void) en éxito
    }

    func updateProductQuantityAsync(cartID: Int, productID: Int, quantity: Int) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/product/\(productID)") else {
             throw ServiceError.invalidURL
        }
         let body: [String: Any] = ["quantity": quantity]
         let request = try createJsonRequest(url: url, method: "PUT", bodyJson: body)
         let (_, httpResponse) = try await performRequest(request: request)

         // PUT suele devolver 200 OK o 204 No Content
         guard (200...299).contains(httpResponse.statusCode) else {
             throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
         }
         print("✅ Quantity for product \(productID) updated to \(quantity) in cart \(cartID).")
         // No devuelve nada (Void) en éxito
    }

     func removeProductFromCartAsync(cartID: Int, productID: Int) async throws {
         guard let url = URL(string: "\(Constants.baseURL)/cart_products/cart/\(cartID)/product/\(productID)") else {
             throw ServiceError.invalidURL
         }
         let request = try createJsonRequest(url: url, method: "DELETE")
         let (_, httpResponse) = try await performRequest(request: request)

         // DELETE suele devolver 200 OK o 204 No Content
         guard (200...299).contains(httpResponse.statusCode) else {
             throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
         }
         print("✅ Product \(productID) removed from cart \(cartID).")
         // No devuelve nada (Void) en éxito
    }


    // MARK: - Original Methods (Completion Handlers - Opcional)

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
