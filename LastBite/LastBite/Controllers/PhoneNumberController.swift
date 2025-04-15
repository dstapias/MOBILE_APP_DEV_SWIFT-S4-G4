//
//  PhoneNumberController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine // Necesario para ObservableObject y Combine

class PhoneNumberController: ObservableObject {

    // MARK: - Published State
    // Almacena solo los dígitos ingresados por el usuario
    @Published var rawPhoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showFourDigitCodeView: Bool = false // Para navegación
    @Published var isPhoneNumberValid: Bool = false // Para habilitar el botón

    // MARK: - Dependencies
    private let userService: SignupUserService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(userService: SignupUserService = SignupUserService.shared) {
        self.userService = userService
        print("📞 PhoneNumberController initialized.")

        // Configura un pipeline de Combine para procesar y validar el número
        setupPhoneNumberPipeline()

        // Opcional: Cargar número existente del servicio si es relevante
        // self.rawPhoneNumber = userService.phoneNumber.replacingOccurrences(of: "+57", with: "") // Ejemplo inicial
    }

    // MARK: - Input Processing Pipeline
    private func setupPhoneNumberPipeline() {
        $rawPhoneNumber
            .removeDuplicates() // Evita procesar el mismo valor dos veces seguidas
            .map { phoneNumber -> String in
                // 1. Filtra para mantener solo los dígitos
                let digitsOnly = phoneNumber.filter { $0.isNumber }
                // 2. Limita a 10 dígitos
                return String(digitsOnly.prefix(10))
            }
            // 3. Reasigna el valor procesado a rawPhoneNumber si cambió
            // Usamos sink en lugar de assign(to:) para evitar bucles si el valor se corta
            .sink { [weak self] processedNumber in
                 guard let self = self else { return }
                 // Solo actualiza si el procesado es diferente al actual para evitar re-disparar
                 if self.rawPhoneNumber != processedNumber {
                     self.rawPhoneNumber = processedNumber
                 }
                 // 4. Actualiza el estado de validez
                 self.isPhoneNumberValid = processedNumber.count == 10
            }
            .store(in: &cancellables) // Guarda la suscripción
    }


    // MARK: - Public Actions
    func sendVerificationCode() {
        // Verifica si el número es válido (10 dígitos) y no está cargando
        guard isPhoneNumberValid, !isLoading else {
            print("⚠️ Cannot send code. Valid: \(isPhoneNumberValid), Loading: \(isLoading)")
            return
        }

        print("📞 Controller attempting to send verification code...")

        // Formatea el número completo con el código de país
        let fullPhoneNumber = "+57" + rawPhoneNumber
        print("   Formatted number: \(fullPhoneNumber)")

        // Actualiza el número en el servicio (importante para el siguiente paso de verificación)
        userService.phoneNumber = fullPhoneNumber

        // Actualiza estado de UI
        isLoading = true
        errorMessage = nil

        // Llama al servicio para enviar el código
        userService.sendVerificationCode { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    print("✅ Controller: Verification code sent successfully to \(fullPhoneNumber).")
                    // Activa la navegación a la pantalla de código
                    self.showFourDigitCodeView = true
                case .failure(let error):
                    print("❌ Controller: Failed to send verification code: \(error.localizedDescription)")
                    self.errorMessage = "Failed to send code. Please try again. (\(error.localizedDescription))"
                    // Opcional: Limpiar el número de teléfono en el servicio si falla?
                    // self.userService.phoneNumber = ""
                }
            }
        }
    }
}

// --- Servicio de Usuario (Asegúrate que exista y tenga 'sendVerificationCode') ---
// class SignupUserService: ObservableObject {
//     static let shared = SignupUserService()
//     @Published var phoneNumber: String = "" // El servicio puede guardar el número formateado
//     @Published var verificationCode: String = "" // Para la siguiente pantalla
//     @Published var selectedAreaId: Int? = nil // Añadido antes
//
//     func sendVerificationCode(completion: @escaping (Result<Void, Error>) -> Void) {
//         print(" MOCK SERVICE: Sending verification code to '\(phoneNumber)'...")
//         // Simula una llamada de red (ej: Firebase Phone Auth)
//         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//             if phoneNumber.count > 5 { // Simulación de éxito simple
//                 print("   MOCK SERVICE: Code supposedly sent.")
//                 completion(.success(()))
//             } else {
//                  print("   MOCK SERVICE: Failed to send code (simulated error).")
//                 completion(.failure(NSError(domain: "SMSError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Simulated send failure."])))
//             }
//         }
//     }
//
//     func verifyCode(completion: @escaping (Result<Void, Error>) -> Void) { ... } // Añadido antes
// }
