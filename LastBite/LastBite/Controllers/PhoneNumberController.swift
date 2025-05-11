//
//  PhoneNumberController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

@MainActor
class PhoneNumberController: ObservableObject {

    // MARK: - Published State
    @Published var rawPhoneNumber: String = "" // Solo dígitos
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showFourDigitCodeView: Bool = false // Navegación
    //@Published var isPhoneNumberValid: Bool = false // Habilita botón

    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()

    init(authRepository: AuthRepository) { // Recibe el repositorio
        self.authRepository = authRepository // Guarda el repositorio
        print("📞 PhoneNumberController initialized with Repository.")
        setupPhoneNumberPipeline() // Configura validación local
    }

    // MARK: - Input Processing Pipeline (Sin Cambios)
    private func setupPhoneNumberPipeline() {
        $rawPhoneNumber
            .removeDuplicates()
            .map { phoneNumber -> String in
                let digitsOnly = phoneNumber.filter { $0.isNumber }
                return String(digitsOnly.prefix(10))
            }
            .sink { [weak self] processedNumber in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.rawPhoneNumber = processedNumber
                }
                 //self.isPhoneNumberValid = processedNumber.count == 10
            }
            .store(in: &cancellables)
    }


    // MARK: - Public Actions (Usa Async/Await y Repositorio)

    /// Intenta enviar el código de verificación usando el repositorio.
    func sendVerificationCode() {
        guard isPhoneNumberValid, !isLoading else {
            print("⚠️ Cannot send code. Valid: \(isPhoneNumberValid), Loading: \(isLoading)")
            return
        }
        print("📞 Controller attempting to send verification code via Repository...")

        let fullPhoneNumber = "+57" + rawPhoneNumber // Formateo sigue aquí
        print("   Formatted number: \(fullPhoneNumber)")

        isLoading = true
        errorMessage = nil

        Task { // Lanza tarea asíncrona
            do {
                // Llama al REPOSITORIO pasando el número formateado
                try await authRepository.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber)
                print("✅ Controller: Verification code sent successfully via Repo.")
                self.showFourDigitCodeView = true // Navega en éxito

            } catch let error as ServiceError { // Captura errores específicos
                 print("❌ Controller: Failed to send verification code via Repo: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription
            } catch { // Otros errores
                 print("❌ Controller: Unexpected error sending code via Repo: \(error.localizedDescription)")
                 self.errorMessage = "Failed to send code. Please try again."
            }
            // Termina la carga
            self.isLoading = false
        }
    }
    
    var isPhoneNumberValid: Bool {
        rawPhoneNumber.filter { $0.isNumber }.count == 10
    }

}
