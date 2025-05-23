//
//  StoreService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation
import CoreLocation // Necesario para el helper si lo usas para Nearby

class StoreService {
    static let shared = StoreService()
    private init() {}

    // --- Helper (Opcional, simplifica llamadas GET) ---
    private func fetchData<T: Decodable>(from url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1) // No es respuesta HTTP
            }
            print("📬 [GET] \(url.absoluteString) -> Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                 // Imprime el cuerpo si hay un error para depurar
                 print("❌ Response Body on Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No body")")
                 throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                // decoder.keyDecodingStrategy = .convertFromSnakeCase // Descomenta si tu JSON usa snake_case
                return try decoder.decode(T.self, from: data)
            } catch {
                 print("❌ Decoding error for \(url.absoluteString): \(error)")
                 print("   Response Data: \(String(data: data, encoding: .utf8) ?? "Non UTF8 data")") // Imprime data en error de decode
                throw ServiceError.decodingError(error)
            }
        } catch let error where !(error is ServiceError) {
             // Captura errores de URLSession.shared.data (ej. red desconectada)
             print("❌ Network Error for \(url.absoluteString): \(error)")
            throw ServiceError.requestFailed(error)
        }
        // Los errores de ServiceError se relanzan automáticamente
    }
    
    private func sendData<B: Encodable>(
        to url: URL,
        method: String,
        body: B?
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add other headers if needed

        if let requestBody = body {
            do {
                request.httpBody = try JSONEncoder().encode(requestBody)
                 if let bodyForPrint = String(data: request.httpBody!, encoding: .utf8) {
                     print("📦 [\(method)] \(url.absoluteString) -> Body: \(bodyForPrint)")
                } else {
                     print("📦 [\(method)] \(url.absoluteString) -> Body: (Non-UTF8 data or empty)")
                }
            } catch {
                print("❌ Encoding error for \(method) to \(url.absoluteString): \(error)")
                throw ServiceError.invalidURL
            }
        } else {
             print("📦 [\(method)] \(url.absoluteString) -> No Body")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1)
            }
            print("📬 [\(method)] \(url.absoluteString) -> Status: \(httpResponse.statusCode)")

            guard (200..<300).contains(httpResponse.statusCode) else {
                print("❌ Response Body on Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No body")")
                throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            // Success, no specific data to decode and return
        } catch let error where !(error is ServiceError) {
            print("❌ Network Error for \(method) to \(url.absoluteString): \(error)")
            throw ServiceError.requestFailed(error)
        }
    }

    // --- Fin Helper ---


    // MARK: - Async Methods

    /// Fetches all main stores asynchronously.
    func fetchStoresAsync() async throws -> [Store] {
        guard let url = URL(string: "\(Constants.baseURL)/stores") else {
            throw ServiceError.invalidURL
        }
        // Llama al helper genérico que hace el fetch y decode
        return try await fetchData(from: url)
    }

    /// Fetches nearby stores based on location asynchronously.
    func fetchNearbyStoresAsync(latitude: Double, longitude: Double) async throws -> [Store] {
        guard let url = URL(string: "\(Constants.baseURL)/stores/nearby?lat=\(latitude)&lon=\(longitude)") else {
            throw ServiceError.invalidURL
        }
        return try await fetchData(from: url)
    }

    /// Fetches top stores asynchronously.
    func fetchTopStoresAsync() async throws -> [Store] {
        guard let url = URL(string: "\(Constants.baseURL)/stores/top") else {
            throw ServiceError.invalidURL
        }
        return try await fetchData(from: url)
    }
    
    func fetchOwnedStoresAsync(for userId: Int) async throws -> [Store] {
        guard let url = URL(string: "\(Constants.baseURL)/user_store/stores/user/\(userId)") else {
            throw ServiceError.invalidURL
        }
        return try await fetchData(from: url)
    }
    
    func updateStoreAsync(_ store: StoreUpdateRequest, store_id: Int) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/stores/\(store_id)") else {
            throw ServiceError.invalidURL
        }
        try await sendData(to: url, method: "PUT", body: store)
    }
    
    func deleteStoreAsync(_ storeId: Int) async throws {
        guard let url = URL(string: "\(Constants.baseURL)/stores/\(storeId)") else {
            throw ServiceError.invalidURL
        }
        try await sendData(to: url, method: "DELETE", body: Optional<String>.none)
    }
    
    func fetchStoreByIdAsync(_ storeId: Int) async throws -> Store {
        guard let url = URL(string: "\(Constants.baseURL)/stores/\(storeId)") else {
            throw ServiceError.invalidURL
        }
        return try await fetchData(from: url)
    }
    
    func createStoreAsync(_ store: StoreCreateRequest) async throws -> Store {
        print(store)
        guard let url = URL(string: "\(Constants.baseURL)/stores") else {
            throw ServiceError.invalidURL
        }
        // Construir request POST con body y decodificar respuesta
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            // Serializar el store a JSON
            let bodyData = try JSONEncoder().encode(store)
            // Imprimir el JSON antes de enviarlo
            if let jsonString = String(data: bodyData, encoding: .utf8) {
                print("📤 [POST] \(url.absoluteString) → JSON Body:\n\(jsonString)")
            }
            request.httpBody = bodyData
        } catch {
            print("❌ Encoding error for POST /stores: \(error)")
            throw ServiceError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.badServerResponse(statusCode: -1)
            }
            print("📦 [POST] \(url.absoluteString) -> Status: \(httpResponse.statusCode)")
            if let body = request.httpBody,
               let jsonAgain = String(data: body, encoding: .utf8) {
                print("🔍 JSON ANTES (recheck):\n\(jsonAgain)")
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                print("❌ Response Body on Error (\(httpResponse.statusCode)): \(String(data: data, encoding: .utf8) ?? "No body")")
                throw ServiceError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            do {
                let decoder = JSONDecoder()
                // decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(Store.self, from: data)
            } catch {
                print("❌ Decoding error for POST /stores: \(error)")
                throw ServiceError.decodingError(error)
            }
        } catch let error where !(error is ServiceError) {
            print("❌ Network Error for POST /stores: \(error)")
            throw ServiceError.requestFailed(error)
        }
    }
}
