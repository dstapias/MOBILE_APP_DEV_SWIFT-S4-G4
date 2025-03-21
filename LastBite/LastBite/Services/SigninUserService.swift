//
//  SignInUserService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

// MARK: - Modelo del Usuario según respuesta del backend
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let mobileNumber: String
    let email: String
    let areaId: Int
    let userType: String
    let description: String?
    let verificationCode: Int

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
        case mobileNumber = "mobile_number"
        case email = "user_email"
        case areaId = "area_id"
        case userType = "user_type"
        case description
        case verificationCode = "verification_code"
    }
}

// MARK: - Servicio de Autenticación y Usuario
class SignInUserService: ObservableObject {
    static let shared = SignInUserService() // ✅ Singleton

    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userId") private var storedUserId: Int = -1 // ✅ Persistente

    @Published var email: String? {
        didSet {
            storedEmail = email ?? ""
        }
    }

    @Published var userId: Int? {
        didSet {
            storedUserId = userId ?? -1
        }
    }

    @Published var password: String? = nil
    @Published var errorMessage: String = ""
    @Published var user: User? = nil

    private init() {
        // ✅ Restaurar email e ID al iniciar la app
        if !storedEmail.isEmpty {
            self.email = storedEmail
        }
        if storedUserId != -1 {
            self.userId = storedUserId
        }

        // Intentar cargar el usuario
        if self.user == nil {
            fetchUserInfo()
        }
    }

    // MARK: - Iniciar sesión con Firebase
    func signInUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let email = email, let password = password else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty."])))
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            } else {
                self.fetchUserInfo() // ✅ Cargar info del usuario desde el backend
                completion(.success(()))
            }
        }
    }

    // MARK: - Reset de contraseña
    func resetPassword(completion: @escaping (Result<String, Error>) -> Void) {
        guard let email = email, !email.isEmpty else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter your email to reset the password."])))
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Password reset link sent to your email."))
            }
        }
    }

    // MARK: - Obtener información del usuario desde el backend
    func fetchUserInfo() {
        guard let email = email else {
            print("❌ Email is nil")
            return
        }

        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Constants.baseURL)/users/email?email=\(encodedEmail)") else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching user info: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❌ No data received")
                return
            }

            do {
                let fetchedUser = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    self.user = fetchedUser
                    self.userId = fetchedUser.id // ✅ Guardar el ID del usuario
                    print("✅ User info fetched: \(fetchedUser.name), ID: \(fetchedUser.id)")
                }
            } catch {
                print("❌ Failed to decode user:", error.localizedDescription)
            }
        }.resume()
    }

    // MARK: - Cerrar sesión
    func signOut() {
        do {
            try Auth.auth().signOut()
            email = nil
            password = nil
            user = nil
            userId = nil
            storedEmail = ""
            storedUserId = -1
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
