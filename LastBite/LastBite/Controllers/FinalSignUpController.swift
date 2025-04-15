//
//  FinalSignUpController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

class FinalSignupController: ObservableObject {

    // MARK: - Published State (Inputs and UI State)
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessMessage: Bool = false // Para el Alert
    @Published var navigateToSignIn: Bool = false // Para la navegación final

    // Validación (se actualiza automáticamente)
    @Published var isEmailValid: Bool = true // Asume válido hasta que se demuestre lo contrario
    @Published var isPasswordValid: Bool = true // Asume válido hasta que se demuestre lo contrario
    @Published var isFormValid: Bool = false // Habilita el botón Submit

    // MARK: - Dependencies
    private let userService: SignupUserService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(userService: SignupUserService = SignupUserService.shared) {
        self.userService = userService
        print("✅ FinalSignupController initialized.")

        // Sincronizar con valores iniciales del servicio si es necesario
        // self.name = userService.name
        // self.email = userService.email
        // self.password = userService.password

        // Configurar pipelines de Combine para validación
        setupValidationPipelines()
    }

    // MARK: - Validation Logic (using Combine)
    private func setupValidationPipelines() {
        // Valida Email
        $email
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Espera un poco
            .map { emailString in
                // Vacío se considera inválido para el submit, pero no muestra error
                if emailString.isEmpty { return true }
                return self.isValidEmailFormat(emailString) // Usa la función helper
            }
            .assign(to: &$isEmailValid) // Asigna a la propiedad publicada

        // Valida Password
        $password
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .map { passwordString in
                 // Vacío se considera inválido para submit, pero no error inmediato
                 if passwordString.isEmpty { return true }
                 return passwordString.count >= 6 // Verifica longitud
            }
            .assign(to: &$isPasswordValid)

        // Valida el Formulario Completo (para habilitar el botón)
        Publishers.CombineLatest3($name, $isEmailValid, $isPasswordValid)
            .map { name, emailIsValid, passwordIsValid in
                // Habilita si nombre no está vacío Y email es válido Y contraseña es válida
                return !name.trimmingCharacters(in: .whitespaces).isEmpty && emailIsValid && passwordIsValid
            }
            .assign(to: &$isFormValid)
    }

    // Helper de validación de email (puede ser privado)
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    // MARK: - Public Actions

    /// Intenta registrar al usuario con los datos actuales.
    func registerUser() {
        guard isFormValid, !isLoading else {
            print("⚠️ Cannot register. Form valid: \(isFormValid), Loading: \(isLoading)")
            return
        }

        print("🚀 Controller attempting user registration...")

        // Actualiza el servicio con los datos del controller ANTES de llamar a la acción
        userService.name = self.name
        userService.email = self.email
        userService.password = self.password
        // userService.userType ya debería estar seteado en el servicio

        isLoading = true
        errorMessage = nil
        showSuccessMessage = false // Resetear estado de éxito

        userService.registerUser { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    print("✅ Controller: User registration successful!")
                    self.showSuccessMessage = true // Muestra el alert de éxito
                case .failure(let error):
                    print("❌ Controller: User registration failed: \(error.localizedDescription)")
                    self.errorMessage = "Registration failed: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Navega a la pantalla de Sign-In (llamado desde el botón "Sign-in" o el alert).
    func goToSignIn() {
        print("Navigating to Sign In screen...")
        self.navigateToSignIn = true
    }
}

// --- Servicio (Asegúrate que tenga 'registerUser') ---
// class SignupUserService: ObservableObject {
//     static let shared = SignupUserService()
//     @Published var name: String = ""
//     @Published var email: String = ""
//     @Published var password: String = ""
//     @Published var phoneNumber: String = "" // Del paso anterior
//     @Published var verificationCode: String = "" // Del paso anterior
//     @Published var selectedAreaId: Int? = nil // Del paso anterior
//     @Published var userType: String = Constants.USER_TYPE_CUSTOMER // Asegúrate que Constants.USER_TYPE_CUSTOMER exista
//
//     func registerUser(completion: @escaping (Result<Void, Error>) -> Void) {
//         print(" MOCK SERVICE: Registering user...")
//         print("   Name: \(name)")
//         print("   Email: \(email)")
//         print("   Password: [HIDDEN]")
//         print("   Phone: \(phoneNumber)")
//         print("   AreaID: \(selectedAreaId ?? -1)")
//         print("   UserType: \(userType)")
//
//         // Simula llamada a API backend para crear el usuario
//         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//             // Simula éxito o fallo
//             if !email.contains("fail") { // Ejemplo de fallo simulado
//                 print("   MOCK SERVICE: User created successfully.")
//                 completion(.success(()))
//             } else {
//                  print("   MOCK SERVICE: User creation failed (simulated).")
//                 completion(.failure(NSError(domain: "SignupError", code: 409, userInfo: [NSLocalizedDescriptionKey: "Email already exists (simulated)."])))
//             }
//         }
//     }
//      // ... otros métodos como sendVerificationCode, verifyCode ...
// }
// --- Fin Servicio ---
