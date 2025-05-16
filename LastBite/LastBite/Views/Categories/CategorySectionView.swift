//
//  CategorySectionView.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import SwiftUI

struct CategorySectionView: View {
    let title: String
    let items: [CategoryItemData]
    let homeController: HomeController
    
    var body: some View {
        let _ = print("➡️ CategorySectionView body: HomeController instance = \(Unmanaged.passUnretained(homeController).toOpaque()) for title: \(title)")

        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: {
                    // Acción al presionar "See all"
                }) {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        CategoryItemView(item: item, homeController: homeController)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}



