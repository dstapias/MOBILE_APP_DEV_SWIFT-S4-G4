//
//  ZoneService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation

class ZoneService {
    static let shared = ZoneService()
    private init() {}

    // --- Helper (Opcional, reutilizado) ---
    private func fetchData<T: Decodable>(from url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1)
            }
            print("📬 [GET] \(url.absoluteString) -> Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                 print("❌ Response Body on Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No body")")
                 throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            do {
                let decoder = JSONDecoder()
                // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si aplica
                return try decoder.decode(T.self, from: data)
            } catch {
                 print("❌ Decoding error for \(url.absoluteString): \(error)")
                 print("   Response Data: \(String(data: data, encoding: .utf8) ?? "Non UTF8 data")")
                throw ServiceError.decodingError(error)
            }
        } catch let error where !(error is ServiceError) {
             print("❌ Network Error for \(url.absoluteString): \(error)")
            throw ServiceError.requestFailed(error)
        }
    }
    // --- Fin Helper ---


    // MARK: - Async Methods

    /// Fetches all zones asynchronously.
    func fetchZonesAsync() async throws -> [Zone] {
        guard let url = URL(string: "\(Constants.baseURL)/zones") else {
            throw ServiceError.invalidURL
        }
        print("📍 ZoneService: Fetching zones from \(url)")
        return try await fetchData(from: url) // Usa el helper
    }

    /// Fetches areas for a specific zone asynchronously.
    func fetchAreasAsync(forZoneId zoneId: Int) async throws -> [Area] {
        guard let url = URL(string: "\(Constants.baseURL)/zones/\(zoneId)/areas") else {
            throw ServiceError.invalidURL
        }
        print("📍 ZoneService: Fetching areas from \(url)")
        return try await fetchData(from: url) // Usa el helper
    }
}
