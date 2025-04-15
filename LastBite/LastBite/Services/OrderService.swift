//  OrderService.swift
//  LastBite
//
//  Created by David Santiago
//

import Foundation

class OrderService {
    static let shared = OrderService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization


    // ✅ Create New Order
    func createOrder(cartId: Int, userId: Int, totalPrice: Double, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/orders") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        let body: [String: Any] = [
            "cart_id": cartId,
            "user_id": userId,
            "status": "ACTIVE",
            "total_price": totalPrice,
            "enabled": 0
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
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let orderId = json["order_id"] as? Int {
                    completion(.success(orderId))
                } else {
                    completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // ✅ Update order status and price
    func updateOrder(orderId: Int, status: String, totalPrice: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/orders/\(orderId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "status": status,
            "total_price": totalPrice
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Server Error", code: 0, userInfo: nil)))
                return
            }

            print("✅ Order updated to status '\(status)' with total price \(totalPrice)")
            completion(.success(()))
        }.resume()
    }

    // ✅ Fetch all orders for a specific user
    func fetchOrdersForUser(userId: Int, completion: @escaping (Result<[Order], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/orders/user/\(userId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching user orders:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let orders = try JSONDecoder().decode([Order].self, from: data)
                completion(.success(orders))
            } catch {
                print("❌ JSON decoding error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }

    // ✅ Fetch NOT RECEIVED orders for a specific user
    func fetchNotReceivedOrdersForUser(userId: Int, completion: @escaping (Result<[Order], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/orders/user/\(userId)/notreceived") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching not received orders:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let orders = try JSONDecoder().decode([Order].self, from: data)
                completion(.success(orders))
            } catch {
                print("❌ JSON decoding error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
    
    // ✅ Mark order as received (enabled = 1)
    func receiveOrder(orderId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/orders/\(orderId)/receive") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "enabled": 1
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Error receiving order:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("❌ Server error. Status code:", statusCode)
                completion(.failure(NSError(domain: "Server Error", code: statusCode, userInfo: nil)))
                return
            }

            print("✅ Order marked as received")
            completion(.success(()))
        }.resume()
    }

}
