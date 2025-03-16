//
//  HomeView.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    
    let bakeryItems = [
        CategoryItemData(title: "Hornitos", imageName: "hornitos"),
        CategoryItemData(title: "Cascabel", imageName: "cascabel")
    ]
    let supermarketItems = [
        CategoryItemData(title: "Éxito", imageName: "exito"),
        CategoryItemData(title: "Jumbo", imageName: "jumbo")
    ]
    let chickenItems = [
        CategoryItemData(title: "KFC", imageName: "kfc"),
        CategoryItemData(title: "Fried Chicken", imageName: "chicken")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    TextField("Search store", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Banner
                    Image("fresh_vegetables_banner")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Sección Bakery
                    CategorySectionView(title: "Bakery", items: bakeryItems)
                    
                    // Sección Supermarkets
                    CategorySectionView(title: "Supermarkets", items: supermarketItems)
                    
                    // Sección Chicken
                    CategorySectionView(title: "Chicken", items: chickenItems)
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
