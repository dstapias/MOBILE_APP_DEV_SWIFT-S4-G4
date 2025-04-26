//
//  APIAuthRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 16/04/25.
//

import Foundation

class APIAuthRepository: AuthRepository {
    private let signInService: SignInUserService
    private let signupService: SignupUserService

    // --- INIT CORREGIDO: Requiere inyección explícita ---
    init(signInService: SignInUserService, signupService: SignupUserService) {
        self.signInService = signInService
        self.signupService = signupService
        print("🔑 APIAuthRepository initialized.")
    }
    // --- FIN INIT ---

    // MARK: - Implementación del Protocolo (Actualizada)

    func signIn(email: String, password: String) async throws {
        // Ya no muta el servicio, solo pasa parámetros
        try await signInService.signInUserAsync(email: email, password: password)
    }

    func resetPassword(email: String) async throws {
        // Ya no muta el servicio, solo pasa parámetros
        try await signInService.resetPasswordAsync(email: email)
    }

    func sendPhoneVerificationCode(phoneNumber: String) async throws {
         // Ya no muta el servicio, solo pasa parámetros
        try await signupService.sendVerificationCodeAsync(phoneNumber: phoneNumber)
    }

    func verifyPhoneCode(code: String) async throws {
        // Ya no muta el servicio, solo pasa parámetros
        try await signupService.verifyCodeAsync(code: code)
    }

    func registerUser(
        name: String, email: String, password: String, phoneNumber: String,
        areaId: Int, userType: String, verificationCode: String
    ) async throws {
        // Ya no muta el servicio, solo pasa parámetros
        try await signupService.registerUserAsync(
            name: name, email: email, password: password, phoneNumber: phoneNumber,
            areaId: areaId, userType: userType, verificationCode: verificationCode
        )
        // Opcional: Llamar a fetchCurrentUserInfo después de registro exitoso?
        // _ = try? await fetchCurrentUserInfo()
    }

    func signOut() {
        Task{
            await signInService.signOut()
        }
    }

    func fetchCurrentUserInfo() async throws -> User {
        try await signInService.fetchUserInfoAsync()
    }
    
    func saveSignupAttempt() async throws {
        try await signupService.saveSignupAttempt()
    }
}
