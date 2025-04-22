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
    }

    // MARK: - Public Actions (Usa Async/Await y Repositorio)

    /// Intenta verificar el código SMS usando el repositorio.
    func verifyCode() {
        guard isCodeComplete, !isLoading else {
            print("⚠️ Cannot verify code. Complete: \(isCodeComplete), Loading: \(isLoading)")
            return
        }
        print("🔢 Controller attempting to verify code via Repository: \(verificationCode)...")


        isLoading = true
        errorMessage = nil

        Task { // Lanza tarea asíncrona
            do {
                // Llama al REPOSITORIO pasando el código local
                try await authRepository.verifyPhoneCode(code: self.verificationCode)
                print("✅ Controller: Code verified successfully via Repo!")
                self.showLocationView = true // Navega en éxito

            } catch let error as ServiceError {
                 print("❌ Controller: Code verification failed via Repo: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription
            } catch {
                 print("❌ Controller: Unexpected code verification error via Repo: \(error.localizedDescription)")
                 self.errorMessage = "Verification failed. Please check the code or request a new one."
            }
             // Termina la carga
            self.isLoading = false
        }
    }
}
