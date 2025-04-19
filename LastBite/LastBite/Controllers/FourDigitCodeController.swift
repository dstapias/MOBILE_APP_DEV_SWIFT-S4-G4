//
//  FourDigitCodeController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor
class FourDigitCodeController: ObservableObject {

    // MARK: - Published State
    @Published var verificationCode: String = "" {
        didSet { // Sigue siendo útil para validación simple y longitud
            if verificationCode.count > 6 {
                verificationCode = String(verificationCode.prefix(6))
            }
            isCodeComplete = verificationCode.count == 6
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showLocationView: Bool = false // Navegación
    @Published var isCodeComplete: Bool = false // Habilita botón

    // --- CAMBIO 1: Dependencia -> AuthRepository ---
    private let authRepository: AuthRepository
    // Ya no necesita SignupUserService directamente para la acción
    private var cancellables = Set<AnyCancellable>()

    // --- CAMBIO 2: Init -> Recibe AuthRepository ---
    init(authRepository: AuthRepository) { // Recibe el repositorio
        self.authRepository = authRepository // Guarda el repositorio
        print("🔢 FourDigitCodeController initialized with Repository.")
        // No necesita pipeline de Combine si el didSet ya hace la validación simple
    }

    // MARK: - Public Actions (Usa Async/Await y Repositorio)

    /// Intenta verificar el código SMS usando el repositorio.
    func verifyCode() {
        guard isCodeComplete, !isLoading else {
            print("⚠️ Cannot verify code. Complete: \(isCodeComplete), Loading: \(isLoading)")
            return
        }
        print("🔢 Controller attempting to verify code via Repository: \(verificationCode)...")

        // Ya no necesitamos asignar a userService.verificationCode

        isLoading = true
        errorMessage = nil

        Task { // Lanza tarea asíncrona
            do {
                // Llama al REPOSITORIO pasando el código local
                try await authRepository.verifyPhoneCode(code: self.verificationCode)
                print("✅ Controller: Code verified successfully via Repo!")
                self.showLocationView = true // Navega en éxito

            } catch let error as ServiceError { // Captura errores específicos
                 print("❌ Controller: Code verification failed via Repo: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription // Muestra error específico
                 // Considera limpiar el código ingresado en caso de error
                 // self.verificationCode = ""
            } catch { // Otros errores
                 print("❌ Controller: Unexpected code verification error via Repo: \(error.localizedDescription)")
                 self.errorMessage = "Verification failed. Please check the code or request a new one."
                 // self.verificationCode = ""
            }
             // Termina la carga
            self.isLoading = false
        }
    }
}

// --- Asegúrate que existan ---
// protocol AuthRepository { func verifyPhoneCode(code: String) async throws ... }
// class APIAuthRepository: AuthRepository { ... }
// enum ServiceError: Error, LocalizedError { ... }
