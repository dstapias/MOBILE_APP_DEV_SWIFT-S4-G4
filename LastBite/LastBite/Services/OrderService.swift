//  OrderService.swift
//  LastBite
//
//  Created by David Santiago
//

import Foundation

class OrderService {
    static let shared = OrderService()
    private init() {}

    // Helper para crear y configurar URLRequest
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

    // Helper para ejecutar data task y validar respuesta básica
    private func performRequest(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1) // No es respuesta HTTP
            }
            print("📬 [\(request.httpMethod ?? "")] \(request.url?.absoluteString ?? "") -> Status: \(httpResponse.statusCode)")
            return (data, httpResponse)
        } catch {
            print("❌ Network Error for \(request.url?.absoluteString ?? ""): \(error)")
            throw ServiceError.requestFailed(error)
        }
    }

    // MARK: - Async Methods

    /// Creates a new order asynchronously. Assumes backend NOW returns the created Order object on success (201).
    func createOrderAsync(cartId: Int, userId: Int, totalPrice: Double) async throws -> Int {
        guard let url = URL(string: "\(Constants.baseURL)/orders") else {
            throw ServiceError.invalidURL
        }

        let body: [String: Any] = [
            "cart_id": cartId, "user_id": userId, "status": "ACTIVE",
            "total_price": totalPrice, "enabled": 0 // O `false` si tu backend prefiere booleanos
        ]
        let request = try createJsonRequest(url: url, method: "POST", bodyJson: body)

        let (data, httpResponse) = try await performRequest(request: request)

        // Create (POST) a menudo devuelve 201 Created
        guard httpResponse.statusCode == 201 else {
             // Imprime el cuerpo si hay un error para depurar
             print("❌ Response Body on Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No body")")
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        // Intenta decodificar el objeto Order completo (asumiendo que el backend lo devuelve)
        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            let order = try decoder.decode(Order.self, from: data)
             print("✅ Decoded created Order object, returning ID: \(order.order_id)")
            return order.order_id
        } catch let decodeError {
            // Si falla, ¿quizás devuelve solo {"order_id": Int}? (Menos ideal)
             print("⚠️ Failed to decode full Order, trying simple {order_id: Int}... Error: \(decodeError)")
             do {
                 if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let orderId = json["order_id"] as? Int {
                     print("✅ Parsed order_id using JSONSerialization: \(orderId)")
                     return orderId
                 } else {
                     throw ServiceError.invalidResponseFormat // El formato sigue sin ser el esperado
                 }
             } catch {
                 throw ServiceError.decodingError(error) // Error en el segundo intento de parseo
             }
        }
    }

    /// Updates an existing order asynchronously. Expects 200 OK on success.
    func updateOrderAsync(orderId: Int, status: String, totalPrice: Double) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/orders/\(orderId)") else {
            throw ServiceError.invalidURL
        }
        let body: [String: Any] = ["status": status, "total_price": totalPrice]
        let request = try createJsonRequest(url: url, method: "PUT", bodyJson: body)

        let (_, httpResponse) = try await performRequest(request: request)

        // Update (PUT) a menudo devuelve 200 OK o 204 No Content
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        print("✅ Order \(orderId) updated successfully.")
        // No devuelve nada (Void) en éxito
    }

    /// Fetches all orders for a specific user asynchronously.
    func fetchOrdersForUserAsync(userId: Int) async throws -> [Order] {
        guard let url = URL(string: "\(Constants.baseURL)/orders/user/\(userId)") else {
            throw ServiceError.invalidURL
        }
        let request = try createJsonRequest(url: url, method: "GET") // GET no necesita body

        let (data, httpResponse) = try await performRequest(request: request)

        guard httpResponse.statusCode == 200 else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            return try decoder.decode([Order].self, from: data)
        } catch {
             print("❌ Decoding error fetching orders for user \(userId): \(error)")
            throw ServiceError.decodingError(error)
        }
    }

    /// Fetches orders not marked as received for a specific user asynchronously.
    func fetchNotReceivedOrdersForUserAsync(userId: Int) async throws -> [Order] {
        guard let url = URL(string: "\(Constants.baseURL)/orders/user/\(userId)/notreceived") else {
            throw ServiceError.invalidURL
        }
        let request = try createJsonRequest(url: url, method: "GET")

        let (data, httpResponse) = try await performRequest(request: request)

        guard httpResponse.statusCode == 200 else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Order].self, from: data)
        } catch {
            print("❌ Decoding error fetching not received orders for user \(userId): \(error)")
            throw ServiceError.decodingError(error)
        }
    }

    /// Marks an order as received asynchronously. Expects 200 OK or 204 No Content.
    func receiveOrderAsync(orderId: Int) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/orders/\(orderId)/receive") else {
            throw ServiceError.invalidURL
        }
        let body: [String: Any] = ["enabled": 1] // O `true` si tu backend prefiere booleanos
        let request = try createJsonRequest(url: url, method: "PUT", bodyJson: body)

        let (_, httpResponse) = try await performRequest(request: request)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        print("✅ Order \(orderId) marked as received.")
        // No devuelve nada (Void) en éxito
    }
}
