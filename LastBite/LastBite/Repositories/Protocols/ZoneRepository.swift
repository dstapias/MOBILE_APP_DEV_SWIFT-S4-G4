//
//  ZoneRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 16/04/25.
//

import Foundation

protocol ZoneRepository {
    /// Obtiene todas las zonas disponibles.
    func fetchZones() async throws -> [Zone]

    /// Obtiene todas las áreas para una zona específica.
    func fetchAreas(zoneId: Int) async throws -> [Area]
}
