//
//  CartService.swift
//  LastBite
//
//  Created by David Santiago on 20/03/25.
//

import Foundation

class CartService {
    static let shared = CartService()
    private init() {}

    // --- Helpers (Reutilizados o copiados de servicios anteriores) ---
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

    /// Fetches the active cart for a given user asynchronously.
    func fetchActiveCartAsync(for userID: Int) async throws -> Cart {
        guard let url = URL(string: "\(Constants.baseURL)/carts/user/\(userID)/active") else {
            throw ServiceError.invalidURL
        }
        let request = try createJsonRequest(url: url, method: "GET")
        let (data, httpResponse) = try await performRequest(request: request)

        // Un carrito activo podría devolver 200 OK o quizás 404 Not Found si no existe
        guard httpResponse.statusCode == 200 else {
            // Podrías querer manejar 404 de forma diferente (ej. devolver nil o un error específico)
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            return try decoder.decode(Cart.self, from: data)
        } catch {
            print("❌ Decoding error fetching active cart for user \(userID): \(error)")
            throw ServiceError.decodingError(error)
        }
    }

    /// Updates the status of a specific cart asynchronously.
    func updateCartStatusAsync(cartId: Int, status: String, userId: Int) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/carts/\(cartId)/status") else {
            throw ServiceError.invalidURL
        }
        let body: [String: Any] = ["status": status, "user_id": userId] // Asegúrate que userId sea necesario aquí según tu API
        let request = try createJsonRequest(url: url, method: "PUT", bodyJson: body)
        let (_, httpResponse) = try await performRequest(request: request)

        // PUT para actualizar estado suele devolver 200 OK o 204 No Content
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        print("✅ Cart \(cartId) status updated to \(status).")
        // No devuelve nada (Void) en éxito
    }
}
