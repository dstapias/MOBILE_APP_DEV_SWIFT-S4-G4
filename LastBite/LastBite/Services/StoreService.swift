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


    // MARK: - Original Methods (Completion Handlers - Opcional)

    func fetchStores(completion: @escaping (Result<[Store], Error>) -> Void) {
        Task { // Llama a la nueva versión async desde la vieja (si necesitas mantenerla)
            do {
                let stores = try await fetchStoresAsync()
                completion(.success(stores))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchNearbyStores(latitude: Double, longitude: Double, completion: @escaping (Result<[Store], Error>) -> Void) {
         Task {
             do {
                 let stores = try await fetchNearbyStoresAsync(latitude: latitude, longitude: longitude)
                 completion(.success(stores))
             } catch {
                 completion(.failure(error))
             }
         }
    }

    func fetchTopStores(completion: @escaping (Result<[Store], Error>) -> Void) {
         Task {
             do {
                 let stores = try await fetchTopStoresAsync()
                 completion(.success(stores))
             } catch {
                 completion(.failure(error))
             }
         }
    }
}
