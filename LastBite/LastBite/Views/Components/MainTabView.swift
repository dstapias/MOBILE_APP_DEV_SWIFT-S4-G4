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
            CartView()
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
            LogoutView()
                            .tabItem {
                                Label("Logout", systemImage: "arrow.backward.circle")
                            }
        }
    }
}

#Preview {
    MainTabView()
}
