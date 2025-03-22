//
//  LogoutView.swift
//  LastBite
//
//  Created by Andrés Romero on 21/03/25.
//

import SwiftUI
import FirebaseAuth

// Vista auxiliar que se encarga de cerrar sesión al aparecer.
struct LogoutView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        Color.clear
            .onAppear {
                do {
                    try Auth.auth().signOut()
                    isLoggedIn = false
                } catch {
                    print("Error al cerrar sesión: \(error.localizedDescription)")
                }
            }
    }
}
