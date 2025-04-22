//
//  SignInUserService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation
import FirebaseAuth
import SwiftUI
import Combine

@MainActor // ✅ Asegura actualizaciones de @Published en hilo principal
class SignInUserService: ObservableObject {
    static let shared = SignInUserService() // ✅ Singleton

    // --- Estado Persistido ---
    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userId") private var storedUserId: Int = -1 // Usa -1 o 0 como indicador de "no ID"

    // --- Estado Publicado (la fuente de verdad para la UI) ---
    // El email y userId se sincronizan con AppStorage
    @Published var email: String? { didSet { storedEmail = email ?? "" } }
    @Published var userId: Int? { didSet { storedUserId = userId ?? -1 } }
    // La contraseña NO se guarda en el servicio después de usarla
    @Published var password: String? = nil
    // El mensaje de error específico de la última operación fallida
    @Published var errorMessage: String = ""
    // El objeto User cargado desde el backend
    @Published var user: User? = nil

    private init() {
        // Restaurar estado desde AppStorage
        if !storedEmail.isEmpty { self.email = storedEmail }
        if storedUserId != -1 { self.userId = storedUserId }

        // Intentar cargar info del usuario si tenemos email/ID pero no el objeto User
        if self.user == nil && (self.userId != nil || self.email != nil) {
             Task {
                 print("🔑 Initializing SignInUserService - Attempting initial user info fetch...")
                 // Intenta buscar info. Si falla, no es crítico aquí, solo loggea.
                 _ = try? await fetchUserInfoAsync() // Llama pero ignora el resultado/error aquí
             }
        } else {
            print("🔑 Initializing SignInUserService - User state: ID=\(String(describing: userId)), Email=\(String(describing: email)), UserObjectPresent=\(user != nil)")
        }
    }

    // MARK: - Async Methods (Aceptan Parámetros)

    /// Inicia sesión con Firebase y busca info del backend, RECIBIENDO email/password.
    func signInUserAsync(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw ServiceError.missingCredentials // Lanza error específico
        }
        print("🔑 Service: Attempting Firebase sign in for \(email)...")
        self.errorMessage = "" // Limpia errores previos

        do {
            // 1. Autentica con Firebase
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ Service: Firebase sign in successful for user: \(authResult.user.uid)")

            // 2. Si Firebase OK, *actualiza el estado interno* del servicio con el email logueado
            self.email = email // <-- IMPORTANTE: Guarda el email para fetchUserInfoAsync

            // 3. Busca info del backend (esta función usa self.email)
            //    Actualizará self.user y self.userId internamente si tiene éxito
            _ = try await fetchUserInfoAsync() // Lanza error si el fetch falla

            // La función retorna Void implícitamente si todo OK

        } catch let error {
            print("❌ Service: Sign In failed: \(error.localizedDescription)")
            self.signOut() // Limpia todo el estado local en caso de fallo
            throw ServiceError.authenticationError(error) // Lanza un error encapsulado
        }
    }

    /// Envía email de reset, RECIBIENDO el email.
    func resetPasswordAsync(email: String) async throws {
        guard !email.isEmpty else {
             throw ServiceError.missingEmailForPasswordReset
         }
        print("🔑 Service: Attempting password reset for \(email)...")
        self.errorMessage = ""

        do {
             try await Auth.auth().sendPasswordReset(withEmail: email) // Usa el parámetro email
             print("✅ Service: Password reset email sent successfully to \(email).")
         } catch let error {
             print("❌ Service: Password Reset failed: \(error.localizedDescription)")
             throw ServiceError.authenticationError(error)
         }
    }

    /// Busca info del usuario en el backend usando el email guardado en el servicio.
    /// Actualiza self.user y self.userId en éxito.
    @discardableResult // Permite llamar sin usar el valor de retorno
    func fetchUserInfoAsync() async throws -> User {
        guard let currentEmail = self.email, !currentEmail.isEmpty else {
            print("❌ Service: fetchUserInfoAsync Error: Email is nil or empty in service")
            throw ServiceError.missingEmailForPasswordReset // O un error tipo "not logged in"
        }

        guard let encodedEmail = currentEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Constants.baseURL)/users/email?email=\(encodedEmail)") else {
            throw ServiceError.invalidURL
        }

        print("🌐 Service: Fetching user info from \(url)...")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
             print("❌ Service: fetchUserInfoAsync Error: Bad server response. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw ServiceError.badServerResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        do {
            let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase // Si aplica
            let fetchedUser = try decoder.decode(User.self, from: data)

            // --- Actualiza el estado del servicio ---
            self.user = fetchedUser
            self.userId = fetchedUser.id // Asume que User tiene id
            self.email = fetchedUser.email // Asegura consistencia del email guardado
             // No limpiamos errorMessage aquí, podría haber uno de una acción anterior
            print("✅ Service: User info fetched and updated: \(fetchedUser.name), ID: \(fetchedUser.id)")
            return fetchedUser // Devuelve el usuario

        } catch {
             print("❌ Service: fetchUserInfoAsync Error: Failed to decode user: \(error.localizedDescription)")
             // Limpia estado si no se pudo decodificar el usuario esperado
             self.user = nil
             self.userId = nil
            throw ServiceError.decodingError(error)
        }
    }

    // MARK: - Cerrar sesión
    func signOut() {
        print("🔑 Service: Signing out...")
        do {
            try Auth.auth().signOut()
            // Limpia todo el estado publicado y persistido
            self.email = nil
            self.password = nil // Limpia la contraseña temporal si estaba
            self.user = nil
            self.userId = nil // Esto actualizará AppStorage a -1
            self.errorMessage = "" // Limpia errores
             print("✅ Service: Sign out successful.")
        } catch let error {
            print("❌ Service: Sign out failed: \(error.localizedDescription)")
            // Establece el mensaje de error
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}


