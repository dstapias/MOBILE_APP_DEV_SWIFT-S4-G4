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
    
    var body: some View {
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
                        CategoryItemView(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategorySectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySectionView(
            title: "Bakery",
            items: [
                CategoryItemData(title: "Hornitos", imageName: "hornitos"),
                CategoryItemData(title: "Cascabel", imageName: "cascabel")
            ]
        )
    }
}

