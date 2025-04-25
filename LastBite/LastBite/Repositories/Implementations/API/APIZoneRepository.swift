//
//  APIZoneRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 16/04/25.
//

import Foundation

class APIZoneRepository: ZoneRepository {
    private let zoneService: ZoneService // Dependencia del servicio async

    init(zoneService: ZoneService = ZoneService.shared) {
        self.zoneService = zoneService
        print("📍 APIZoneRepository initialized.")
    }

    func fetchZones() async throws -> [Zone] {
        // Llama al método async del servicio
        try await zoneService.fetchZonesAsync()
    }

    func fetchAreas(zoneId: Int) async throws -> [Area] {
        // Llama al método async del servicio
        try await zoneService.fetchAreasAsync(forZoneId: zoneId)
    }
}
