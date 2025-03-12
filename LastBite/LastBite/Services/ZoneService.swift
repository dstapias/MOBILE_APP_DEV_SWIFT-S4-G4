//
//  ZoneService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//
import Foundation

class ZoneService {
    static let shared = ZoneService() // ✅ Singleton instance

    private init() {} // Prevents accidental initialization

    struct Zone: Codable {
        let zone_id: Int
        let zone_name: String
    }

    struct Area: Codable {
        let area_id: Int
        let area_name: String
    }

    // Fetch Zones from Backend
    func fetchZones(completion: @escaping (Result<[Zone], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/zones") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching zones:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Zone].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }

    // fetch zone areas
    func fetchAreas(forZoneId zoneId: Int, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/zones/\(zoneId)/areas") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching areas:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("Error: No Data Received")
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Area].self, from: data)
                let areaNames = decodedResponse.map { $0.area_name } // Extract only names
                completion(.success(areaNames))
            } catch {
                print("JSON Decoding Error:", error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
}

