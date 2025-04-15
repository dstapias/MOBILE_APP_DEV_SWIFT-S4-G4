//
//  SignupController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine // Necesario para ObservableObject

class SignupController: ObservableObject {

    // MARK: - Published State
    @Published var showPhoneNumberView: Bool = false // Controla la navegación

    // Podrías añadir aquí estados para isLoading o errorMessage si las
    // acciones de social login fueran asíncronas y pudieran fallar.

    // MARK: - Initialization
    init() {
        print("👋 SignupController initialized.")
        // Aquí podrías inyectar servicios si fueran necesarios (ej: para social login)
    }

    // MARK: - Public Actions

    /// Inicia el flujo de registro con número de teléfono.
    func startPhoneNumberSignup() {
        print("▶️ User initiated phone number signup.")
        showPhoneNumberView = true // Activa la navegación en la vista
    }

    /// Inicia el flujo de registro con Google (Placeholder).
    func signInWithGoogle() {
        // TODO: Implementar lógica de inicio de sesión con Google SDK
        print("▶️ User initiated Google sign in (Not Implemented Yet).")
        // Aquí llamarías al SDK, manejarías el resultado, posiblemente
        // llamarías a tu backend, actualizarías userService.isLoggedIn, etc.
        // Podrías necesitar estados @Published isLoadingGoogle, errorMessageGoogle, etc.
    }

    /// Inicia el flujo de registro con Facebook (Placeholder).
    func signInWithFacebook() {
        // TODO: Implementar lógica de inicio de sesión con Facebook SDK
        print("▶️ User initiated Facebook sign in (Not Implemented Yet).")
        // Similar a Google Sign in.
    }
}
