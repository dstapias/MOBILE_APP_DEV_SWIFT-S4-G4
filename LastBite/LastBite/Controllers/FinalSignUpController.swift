//
//  FinalSignUpController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine

@MainActor
class FinalSignupController: ObservableObject {

    // MARK: - Published State (Inputs locales y estado UI)
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessMessage: Bool = false // Para el Alert
    @Published var navigateToSignIn: Bool = false // Para la navegación final
    @Published var isEmailValid: Bool = true
    @Published var isPasswordValid: Bool = true
    @Published var isFormValid: Bool = false // Habilita botón Submit

    private let authRepository: AuthRepository
    private let signupStateService: SignupUserService
    private var cancellables = Set<AnyCancellable>()

    init(
        authRepository: AuthRepository,
        signupStateService: SignupUserService = SignupUserService.shared
    ) {
        self.authRepository = authRepository
        self.signupStateService = signupStateService
        print("✅ FinalSignupController initialized with Repository.")

        setupValidationPipelines() // Configura validación local
    }

    // MARK: - Validation Logic
    private func setupValidationPipelines() {
         Publishers.CombineLatest3($name, $isEmailValid, $isPasswordValid)
             .map { name, emailIsValid, passwordIsValid in
                 let isNameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
                 return isNameValid && emailIsValid && passwordIsValid
             }
             .assign(to: &$isFormValid)

         $email
             .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
             .map { self.isValidEmailFormat($0) }
             .assign(to: &$isEmailValid)

         $password
             .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
             .map { $0.count >= 6 }
             .assign(to: &$isPasswordValid)
    }

    private func isValidEmailFormat(_ email: String) -> Bool {
        if email.isEmpty { return true } // Vacío no es inválido per se
        let emailRegEx = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    // MARK: - Public Actions (Usa Async/Await y Repositorio)

    /// Intenta registrar al usuario final usando el repositorio.
    func registerUser() {
        guard isFormValid, !isLoading else {
            print("⚠️ Cannot register. Form valid: \(isFormValid), Loading: \(isLoading)")
            errorMessage = isFormValid ? nil : "Please fill all fields correctly." // Da feedback si el form no es válido
            return
        }

        // Recupera los datos necesarios del servicio de estado
        guard !signupStateService.phoneNumber.isEmpty else {
            errorMessage = "Phone number is missing. Please go back."
            return
        }
        let phoneNumber = signupStateService.phoneNumber
         guard let areaId = signupStateService.selectedAreaId else {
             errorMessage = "Area selection is missing. Please go back."
             return
         }
         let userType = signupStateService.userType
         let verificationCode = signupStateService.verificationCode

        print("🚀 Controller attempting final user registration via Repository...")


        isLoading = true
        errorMessage = nil
        showSuccessMessage = false

        Task {
            do {
                // Llama al REPOSITORIO pasando TODOS los datos requeridos
                try await authRepository.registerUser(
                    name: self.name,
                    email: self.email,
                    password: self.password, // Pasa la contraseña para Firebase Auth
                    phoneNumber: phoneNumber,
                    areaId: areaId,
                    userType: userType,
                    verificationCode: verificationCode
                )
                print("✅ Controller: User registration successful via Repo!")
                self.showSuccessMessage = true // Muestra alert de éxito

            } catch let error as ServiceError { // Captura errores específicos
                print("❌ Controller: User registration failed via Repo: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            } catch { // Otros errores
                print("❌ Controller: Unexpected registration error via Repo: \(error.localizedDescription)")
                self.errorMessage = "An unexpected error occurred during registration."
            }
            // Termina la carga
            self.isLoading = false
        }
    }

    // MARK: - Navegación
    func goToSignIn() {
        print("Navigating to Sign In screen...")
        self.navigateToSignIn = true
    }
}
