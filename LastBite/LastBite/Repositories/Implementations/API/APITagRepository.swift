//
//  APITagRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 19/04/25.
//

import Foundation

class APITagRepository: TagRepository {
    private let tagService: TagService // Dependencia del servicio async

    init(tagService: TagService = TagService.shared) {
        self.tagService = tagService
        print("🏷️ APITagRepository initialized.")
    }

    func fetchTags(for productId: Int) async throws -> [Tag] {
        // Llama directamente al método async del servicio
        try await tagService.fetchTagsAsync(for: productId)
    }
}
