//
//  MainTabView.swift
//  LastBite
//
//  Created by Andrés Romero on 16/03/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var signInService: SignInUserService
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showBanner = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {        // ancla arriba
                TabView {
                    HomeView()
                        .tabItem { Label("Shop", systemImage: "house") }
                    
                    CartView(signInService: signInService,
                             networkMonitor: networkMonitor)
                    .tabItem { Label("Cart", systemImage: "cart") }
                    
                    LogoutView()
                        .tabItem { Label("Logout", systemImage: "arrow.backward.circle") }
                }
                
                // ───── Banner ─────
                if showBanner {
                    HStack {
                        Image(systemName: "wifi.exclamationmark")
                        Text("No Internet Connection")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.95))
                    .foregroundColor(.white)
                    .transition(.move(edge: .top))
                    .zIndex(1)                      // ← por encima del TabView
                }
            }
            .animation(.easeInOut, value: showBanner)
            
            // actualiza según la conectividad
            .onReceive(networkMonitor.$isConnected) { connected in
                showBanner = !connected
            }
        }
    }
}
