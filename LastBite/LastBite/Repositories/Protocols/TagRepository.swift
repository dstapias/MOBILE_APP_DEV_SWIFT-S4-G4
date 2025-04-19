//
//  TagRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 19/04/25.
//

import Foundation

protocol TagRepository {
    /// Obtiene los tags asociados a un ID de producto.
    func fetchTags(for productId: Int) async throws -> [Tag]
}
