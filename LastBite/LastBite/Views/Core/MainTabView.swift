//
//  MainTabView.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import SwiftUI

struct MainTabView: View {
    // 1. Accede al servicio desde el entorno
    @EnvironmentObject var signInService: SignInUserService

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Shop", systemImage: "house")
                }

            // 2. Pasa el servicio obtenido del entorno a CartView
            CartView(signInService: signInService)
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


