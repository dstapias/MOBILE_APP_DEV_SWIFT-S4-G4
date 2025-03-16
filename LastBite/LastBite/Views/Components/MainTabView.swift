//
//  MainTabView.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Shop", systemImage: "house")
                }
            
            Text("Explore")
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
            
            Text("Cart")
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
            
            Text("Favourite")
                .tabItem {
                    Label("Favourite", systemImage: "heart")
                }
            
            Text("Account")
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
}
