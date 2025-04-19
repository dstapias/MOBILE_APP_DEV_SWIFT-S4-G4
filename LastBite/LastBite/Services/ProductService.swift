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


    // MARK: - Original Method (Completion Handler - Opcional)

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
