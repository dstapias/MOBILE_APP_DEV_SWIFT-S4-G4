//
//  CategoryItemData.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import Foundation

struct CategoryItemData: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    var store: StoreService.Store? = nil 
}
