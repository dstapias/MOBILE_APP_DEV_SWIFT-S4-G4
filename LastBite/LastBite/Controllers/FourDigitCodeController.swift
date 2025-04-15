//
//  FourDigitCodeController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine // Necesario para ObservableObject y Combine

class FourDigitCodeController: ObservableObject {

    // MARK: - Published State
    @Published var verificationCode: String = "" {
        // Asegura que el código no exceda los 6 dígitos
        // Esto se puede hacer aquí o con un pipeline de Combine en init
        didSet {
            if verificationCode.count > 6 {
                // Corta el string si excede los 6 caracteres
                verificationCode = String(verificationCode.prefix(6))
            }
             // Actualiza si el código está completo (podría hacerse con Combine también)
             isCodeComplete = verificationCode.count == 6
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showLocationView: Bool = false // Para la navegación
    @Published var isCodeComplete: Bool = false // Derivado de verificationCode

    // MARK: - Dependencies
    private let userService: SignupUserService
    private var cancellables = Set<AnyCancellable>() // Para futuras suscripciones si se necesitan

    // MARK: - Initialization
    init(userService: SignupUserService = SignupUserService.shared) {
        self.userService = userService
        print("🔢 FourDigitCodeController initialized.")

        // Opcional: Sincronizar el código inicial si el servicio ya tiene uno
         // self.verificationCode = userService.verificationCode

        // Configurar pipeline de Combine para la lógica del código (alternativa al didSet)
        // setupCodePipeline()
    }

    // Opcional: Ejemplo de cómo hacerlo con Combine (alternativa al didSet)
    /*
    private func setupCodePipeline() {
        $verificationCode
            .map { $0.count == 6 } // Deriva si está completo
            .assign(to: &$isCodeComplete) // Asigna a la propiedad publicada

        $verificationCode
            .filter { $0.count > 6 } // Si se excede
            .map { String($0.prefix(6)) } // Córtalo
            .assign(to: &$verificationCode) // Reasigna a la propiedad publicada
    }
     */


    // MARK: - Public Actions
    func verifyCode() {
        guard isCodeComplete, !isLoading else {
            print("⚠️ Cannot verify code. Complete: \(isCodeComplete), Loading: \(isLoading)")
            return
        }

        print("🔢 Controller attempting to verify code: \(verificationCode)...")

        // Pasa el código del controller al servicio ANTES de llamar a la acción
        userService.verificationCode = self.verificationCode

        // Actualiza estado de UI
        isLoading = true
        errorMessage = nil

        userService.verifyCode { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    print("✅ Controller: Code verified successfully!")
                    // Activa la navegación a la siguiente pantalla
                    self.showLocationView = true
                case .failure(let error):
                     print("❌ Controller: Code verification failed: \(error.localizedDescription)")
                     // Actualiza el mensaje de error para la vista
                     self.errorMessage = "Verification failed: \(error.localizedDescription)"
                     // Opcional: Limpiar el código después de un error?
                     // self.verificationCode = ""
                }
            }
        }
    }
}

// --- Servicio de Usuario (Asegúrate que exista y tenga 'verifyCode') ---
// class SignupUserService: ObservableObject {
//     static let shared = SignupUserService()
//     @Published var verificationCode: String = ""
//     @Published var selectedAreaId: Int? = nil // Añadido antes
//     func verifyCode(completion: @escaping (Result<Void, Error>) -> Void) {
//         print(" MOCK SERVICE: Verifying code '\(verificationCode)'...")
//         // Simula una llamada de red
//         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//             if self.verificationCode == "123456" { // Código de ejemplo
//                 completion(.success(()))
//             } else {
//                 completion(.failure(NSError(domain: "VerificationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid code entered."])))
//             }
//         }
//     }
// }
