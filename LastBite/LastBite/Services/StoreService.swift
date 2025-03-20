//
//  StoreService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class StoreService {
    static let shared = StoreService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct Store: Codable {
        let store_id: Int
        let name: String
        let address: String
        let latitude: Double
        let longitude: Double
        let logo: String
        let nit: String
    }

    // Fetch Stores from Backend
    func fetchStores(completion: @escaping (Result<[Store], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/stores") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching stores:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Store].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
}
