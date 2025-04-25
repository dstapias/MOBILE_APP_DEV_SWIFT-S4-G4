//
//  ProductService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class ProductService {
    static let shared = ProductService()
    private init() {}

    // --- Helpers (Opcionales, podrías usar los definidos en otros servicios si están compartidos) ---
    private func performRequest(url: URL) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1)
            }
            print("📬 [GET] \(url.absoluteString) -> Status: \(httpResponse.statusCode)")
            return (data, httpResponse)
        } catch {
            print("❌ Network Error for \(url.absoluteString): \(error)")
            throw ServiceError.requestFailed(error)
        }
    }
    // --- Fin Helpers ---


    // MARK: - Async Method

    /// Fetches products for a specific store asynchronously.
    func fetchProductsAsync(for storeID: Int) async throws -> [Product] {
        guard let url = URL(string: "\(Constants.baseURL)/products/store/\(storeID)") else {
            throw ServiceError.invalidURL
        }
        print("📦 ProductService: Fetching products from \(url)")

        let (data, httpResponse) = try await performRequest(url: url) // Usa helper o URLSession directo

        guard httpResponse.statusCode == 200 else {
            throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
             // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            return try decoder.decode([Product].self, from: data)
        } catch {
            print("❌ Decoding error fetching products for store \(storeID): \(error)")
            // Podrías imprimir data como string aquí para depurar si falla la decodificación
            // print("   Response Data: \(String(data: data, encoding: .utf8) ?? "Non UTF8 data")")
            throw ServiceError.decodingError(error)
        }
    }
    
    func createProduct(_ product: ProductCreateRequest) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/products") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(product)
        } catch {
            print("❌ Failed to encode product: \(error)")
            throw ServiceError.serializationError(error)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("❌ Bad server response: HTTP \(code)")
                throw ServiceError.badServerResponse(statusCode: code)
            }

            print("✅ Product created successfully.")

        } catch {
            print("❌ Network error while creating product: \(error)")
            throw ServiceError.requestFailed(error)
        }
    }

}
