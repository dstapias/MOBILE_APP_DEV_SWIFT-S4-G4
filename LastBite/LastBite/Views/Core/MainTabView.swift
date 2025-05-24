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
    @State private var selectedTab: Int = 0 // 0 = Home, 1 = Cart, 2 = Logout
    @StateObject private var homeController: HomeController // MainTabView es el dueño
    
    init(networkMonitor: NetworkMonitor, signInService: SignInUserService) {
            // --- Inicializar HomeController ---
            let apiStoreRepo = APIStoreRepository()
            let localStoreRepo = LocalStoreRepository() // Asumiendo init() no failable ya
            
            let locManagerForHome = LocationManager() // HomeController crea y maneja su propio LocationManager o lo recibe
                                                     // Si HomeController lo crea, no necesitas esta línea aquí.
                                                     // Si HomeController lo recibe, y MainTabView lo crea, está bien.
                                                     // Basado en tu HomeController.init, él recibe un LocationManager.

            let hybridRepo = HybridStoreRepository(
                apiRepository: apiStoreRepo,
                localRepository: localStoreRepo,
                networkMonitor: networkMonitor, // <--- Usa el parámetro del init de MainTabView
                firebaseService: FirebaseService.shared
            )
            let orderRepoForHome = APIOrderRepository()

            let hCtrl = HomeController(
                signInService: signInService,   // <--- Usa el parámetro del init de MainTabView
                locationManager: locManagerForHome, // Pasa la instancia creada
                storeRepository: hybridRepo,
                orderRepository: orderRepoForHome,
                networkMonitor: networkMonitor  // <--- Usa el parámetro del init de MainTabView
            )
            self._homeController = StateObject(wrappedValue: hCtrl)

            // --- Inicializar CartController ---
            // Si tu LocalCartRepository tiene un init?(), necesitas desenvolverlo con guard let:
            
            print("🚀 MainTabView initialized. HomeController and CartController created with injected dependencies (networkMonitor, signInService).")
        }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {        // ancla arriba
                TabView(selection: $selectedTab) {
                    HomeView(controller: homeController, networkMonitor: networkMonitor, signInService: signInService)
                        .tabItem { Label("Shop", systemImage: "house") }
                        .tag(0) // 3. Assign a tag to each view

                    
                    CartView(signInService: signInService,
                             networkMonitor: networkMonitor, selectedTab: $selectedTab)
                    .tabItem { Label("Cart", systemImage: "cart") }
                    .tag(1) // 3. Assign a tag

                    
                    LogoutView()
                        .tabItem { Label("Logout", systemImage: "arrow.backward.circle") }
                        .tag(2) // 3. Assign a tag

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
