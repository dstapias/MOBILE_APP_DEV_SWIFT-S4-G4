//
//  SigninController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor
class SignInController: ObservableObject {

    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var didSignInSuccessfully: Bool = false

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        // No sincronizamos email/password al inicio, la vista empieza limpia
        print("🔑 SignInController initialized with Repository.")
    }

    // MARK: - Public Actions (Usa Async/Await y Repositorio)

    /// Intenta iniciar sesión usando el repositorio.
    func signInUser() {
        print("🔑 Controller attempting sign in via Repository...")
        isLoading = true
        errorMessage = nil
        successMessage = nil
        didSignInSuccessfully = false

        Task {
            do {
                // Llama al REPOSITORIO pasando los datos locales
                try await authRepository.signIn(email: self.email, password: self.password)
                print("✅ Controller: Sign in successful via Repo.")
                self.didSignInSuccessfully = true // Notifica a la vista en éxito

            } catch let error as ServiceError { // Captura errores específicos
                 print("❌ Controller: Sign in failed via Repo: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription // Muestra error
                 self.password = "" // Limpia contraseña local en fallo

            } catch { // Otros errores inesperados
                 print("❌ Controller: Unexpected Sign in error via Repo: \(error.localizedDescription)")
                 self.errorMessage = "An unexpected error occurred during sign in."
                 self.password = ""
            }
            // Termina la carga
            self.isLoading = false
        }
    }

    /// Intenta resetear la contraseña usando el repositorio.
    func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            successMessage = nil
            return
        }
        print("🔑 Controller attempting password reset via Repository...")

        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
             do {
                 // Llama al REPOSITORIO pasando el email local
                 try await authRepository.resetPassword(email: self.email)
                 print("✅ Controller: Password reset email sent via Repo.")
                 // Mensaje de éxito gestionado por el controller
                 self.successMessage = "Password reset link sent to \(self.email)."

             } catch let error as ServiceError { // Captura errores específicos
                 print("❌ Controller: Password reset failed via Repo: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription
             } catch { // Otros errores
                 print("❌ Controller: Unexpected Password reset error via Repo: \(error.localizedDescription)")
                 self.errorMessage = "Failed to send password reset email."
             }
            self.isLoading = false // Termina la carga
         }
    }
}
