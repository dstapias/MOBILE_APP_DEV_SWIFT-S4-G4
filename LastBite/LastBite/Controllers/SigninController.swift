//
//  SigninController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine // Necesario

class SignInController: ObservableObject {

    // MARK: - Published Properties (Estado para la Vista)
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil // Mensaje de error de las acciones
    @Published var successMessage: String? = nil // Mensaje de éxito (ej: reset password)
    @Published var didSignInSuccessfully: Bool = false // Para notificar a la vista

    // MARK: - Dependencies
    // Puede ser inyectado o usar el singleton
    private let authService: SignInUserService

    // MARK: - Initialization
    init(authService: SignInUserService = SignInUserService.shared) {
        self.authService = authService
        // Sincronizar con el estado inicial del servicio si es necesario
        // (Aunque generalmente el usuario empieza con campos vacíos en esta pantalla)
         self.email = authService.email ?? ""
         print("🔑 SignInController initialized.")
    }

    // MARK: - Public Actions

    /// Intenta iniciar sesión usando los datos actuales del controller.
    func signInUser() {
        print("🔑 Controller attempting sign in...")
        // Asigna los valores del controller al servicio ANTES de llamar a la acción
        authService.email = self.email
        authService.password = self.password

        // Actualiza el estado de carga y limpia mensajes previos
        isLoading = true
        errorMessage = nil
        successMessage = nil
        didSignInSuccessfully = false // Resetear estado de éxito

        authService.signInUser { [weak self] result in
            guard let self = self else { return }
            // Siempre actualiza la UI en el hilo principal
            DispatchQueue.main.async {
                self.isLoading = false // Termina la carga
                switch result {
                case .success:
                    print("✅ Controller: Sign in successful.")
                    // El userId ya debería estar actualizado en authService.shared
                    // Notifica a la vista que el login fue exitoso
                    self.didSignInSuccessfully = true
                case .failure(let error):
                    print("❌ Controller: Sign in failed: \(error.localizedDescription)")
                    // Usa el mensaje de error del servicio o uno propio
                    self.errorMessage = self.authService.errorMessage.isEmpty ? error.localizedDescription : self.authService.errorMessage
                    // Limpia la contraseña por seguridad después de un fallo
                    self.password = ""
                    // Limpia la contraseña en el servicio también
                    self.authService.password = nil
                }
            }
        }
    }

    /// Intenta resetear la contraseña para el email actual del controller.
    func resetPassword() {
        print("🔑 Controller attempting password reset...")
        // Asegúrate que el email esté en el servicio
        authService.email = self.email

        // Limpia mensajes previos
        // isLoading no se usa aquí, pero podrías añadirlo si la operación tarda
        errorMessage = nil
        successMessage = nil

        authService.resetPassword { [weak self] result in
             guard let self = self else { return }
             DispatchQueue.main.async {
                switch result {
                case .success(let message):
                     print("✅ Controller: Password reset email sent.")
                    self.successMessage = message // Muestra el mensaje de éxito
                case .failure(let error):
                     print("❌ Controller: Password reset failed: \(error.localizedDescription)")
                    // Intenta obtener el mensaje de error específico del servicio
                    self.errorMessage = self.authService.errorMessage.isEmpty ? error.localizedDescription : self.authService.errorMessage
                }
            }
        }
    }
}
