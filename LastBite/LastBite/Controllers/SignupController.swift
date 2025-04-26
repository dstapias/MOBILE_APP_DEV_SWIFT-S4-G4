//
//  SignupController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

class SignupController: ObservableObject {

    // MARK: - Published State
    @Published var showPhoneNumberView: Bool = false


    // MARK: - Initialization
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) { // Recibe el repositorio
        self.authRepository = authRepository // Guarda el repositorio
        print("👋 SignupController initialized with Repository.")
    }

    // MARK: - Public Actions

    /// Inicia el flujo de registro con número de teléfono.
    func startPhoneNumberSignup() {
        print("▶️ User initiated phone number signup.")
        do{
            Task {
                try await authRepository.saveSignupAttempt()
            }
        }
        showPhoneNumberView = true // Activa la navegación en la vista
    }

    /// Inicia el flujo de registro con Google (Placeholder).
    func signInWithGoogle() {
        print("▶️ User initiated Google sign in (Not Implemented Yet).")

    }

    /// Inicia el flujo de registro con Facebook (Placeholder).
    func signInWithFacebook() {
        // TODO: Implementar lógica de inicio de sesión con Facebook SDK
        print("▶️ User initiated Facebook sign in (Not Implemented Yet).")
    }
}
