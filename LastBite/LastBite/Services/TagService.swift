//
//  TagService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation


class TagService {
    static let shared = TagService()
    private init() {}

    // --- Helpers (Reutilizados o copiados de servicios anteriores) ---
    // No necesitamos createJsonRequest ni performRequest aquí ya que es un GET simple,
    // pero podrías usarlos si prefieres consistencia. Vamos a hacerlo directo.

    // MARK: - Async Method

    /// Fetches tags for a specific product asynchronously.
    func fetchTagsAsync(for productID: Int) async throws -> [Tag] {
        guard let url = URL(string: "\(Constants.baseURL)/tags/product/\(productID)") else {
            throw ServiceError.invalidURL
        }
        print("🏷️ TagService: Fetching tags from \(url)")

        // Llama directo a URLSession con async/await
        let data: Data
        let response: URLResponse
        do {
             (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print("❌ TagService: Network Error fetching tags for product \(productID): \(error)")
            throw ServiceError.requestFailed(error)
        }

        // Verifica la respuesta HTTP
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ TagService: Bad server response fetching tags. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw ServiceError.badServerResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        // Decodifica la respuesta
        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si es necesario
            return try decoder.decode([Tag].self, from: data)
        } catch {
            print("❌ TagService: Decoding error fetching tags for product \(productID): \(error)")
            // Podrías imprimir data como string aquí para depurar si falla la decodificación
            // print("   Response Data: \(String(data: data, encoding: .utf8) ?? "Non UTF8 data")")
            throw ServiceError.decodingError(error)
        }
    }
}
