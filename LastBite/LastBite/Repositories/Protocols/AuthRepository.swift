//
//  AuthRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 16/04/25.
//

import Foundation

// Protocolo para operaciones de Autenticación y Registro de Usuario
protocol AuthRepository {

    // --- Autenticación Email/Password ---
    /// Inicia sesión con email y contraseña. Actualiza el estado interno del servicio.
    func signIn(email: String, password: String) async throws

    /// Envía un correo para resetear la contraseña.
    func resetPassword(email: String) async throws

    // --- Autenticación Teléfono ---
    /// Envía un código de verificación SMS al número proporcionado.
    func sendPhoneVerificationCode(phoneNumber: String) async throws

    /// Verifica el código SMS recibido y autentica la sesión de teléfono.
    func verifyPhoneCode(code: String) async throws

    // --- Registro ---
    /// Registra un nuevo usuario (backend + Firebase Auth).
    /// Nota: Asume que los datos necesarios (nombre, areaId, etc.) están disponibles
    /// en los servicios o se pasan aquí. Pasarlos es más explícito.
    func registerUser(
        name: String,
        email: String,
        password: String,
        phoneNumber: String, // Formato completo (+57...)
        areaId: Int,
        userType: String,
        verificationCode: String // Código SMS (¿necesario en el backend?)
    ) async throws
    // --- Sesión ---
    /// Cierra la sesión actual (Firebase y limpia estado local).
    func signOut() // Esta suele ser síncrona

    /// Obtiene la información del usuario del backend (si está logueado).
    /// Devuelve User o lanza error si no se puede obtener.
    func fetchCurrentUserInfo() async throws -> User
    
    
    func saveSignupAttempt() async throws
}
