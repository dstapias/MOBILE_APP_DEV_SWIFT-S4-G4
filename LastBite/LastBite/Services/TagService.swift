//
//  TagService.swift
//  LastBite
//
//  Created by David Santiago on 19/03/25.
//

import Foundation

class TagService {
    static let shared = TagService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct Tag: Codable {
        let product_id: Int
        let product_tag_id: Int
        let value: String // ✅ Stores tag value (e.g., "Organic", "Gluten-Free")
    }

    // ✅ Fetch Tags for a Product
    func fetchTags(for productID: Int, completion: @escaping (Result<[Tag], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/tags/product/\(productID)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching tags:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Tag].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("❌ JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
}
