//
//  SignupUserService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation
import FirebaseAuth
import SwiftUI
import Combine



@MainActor
class SignupUserService: ObservableObject {
    static let shared = SignupUserService()


    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var selectedAreaId: Int?
    @Published var verificationCode: String = ""
    @Published var userType: String = Constants.USER_TYPE_CUSTOMER
    @Published var password: String = ""

    private let baseURL = Constants.baseURL
    private init() {
        print("👤 SignupUserService initialized.")
    }

    // MARK: - Async Methods (Aceptan Parámetros)
    
    func saveSignupAttempt() async throws {
        print("👤 Service: Saving signup attempt async...")
        try await saveSignupAttemptAsync()
    }

    /// Registra usuario en backend y Firebase, RECIBIENDO todos los datos.
    func registerUserAsync(
        name: String, email: String, password: String, phoneNumber: String,
        areaId: Int, userType: String, verificationCode: String
    ) async throws {
        print("👤 Service: Registering user async...")

        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.selectedAreaId = areaId
        self.userType = userType

        // 1. Llama al backend
        try await registerUserInBackendAsync(
            name: name, email: email, phoneNumber: phoneNumber,
            areaId: areaId, userType: userType, verificationCode: verificationCode
        )
        print("✅ Service: Backend registration successful.")

        // 2. Llama a Firebase Auth
        try await registerUserInFirebaseAsync(email: email, password: password)
        print("✅ Service: Firebase registration successful.")
    }

    /// Envía código SMS, RECIBIENDO el número.
    func sendVerificationCodeAsync(phoneNumber: String) async throws {
        guard !phoneNumber.isEmpty else { throw ServiceError.missingPhoneNumber }
        print("👤 Service: Sending verification code async to \(phoneNumber)...")

        // Guarda el número formateado en el servicio para referencia futura si es necesario
        self.phoneNumber = phoneNumber

        let verificationID: String = try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    print("❌ Service: Firebase Error sending code: \(error.localizedDescription)")
                    continuation.resume(throwing: ServiceError.authenticationError(error))
                } else if let verificationID = verificationID {
                    print("✅ Service: Verification ID obtained: \(verificationID)")
                    continuation.resume(returning: verificationID)
                } else {
                    print("❌ Service: Unknown error obtaining verification ID.")
                    continuation.resume(throwing: ServiceError.authenticationError(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error sending verification code."])))
                }
            }
        }

        // Guarda el ID de verificación para usarlo después
        UserDefaults.standard.set(verificationID, forKey: "verificationID_async")
        print("✅ Service: Verification ID saved to UserDefaults.")
    }

    /// Verifica código SMS, RECIBIENDO el código.
    func verifyCodeAsync(code: String) async throws {
        guard let verificationID = UserDefaults.standard.string(forKey: "verificationID_async") else {
             print("❌ Service: Verification ID not found in UserDefaults.")
            throw ServiceError.missingVerificationId
        }
        guard !code.isEmpty else {
            print("❌ Service: Verification code is empty.")
            throw ServiceError.missingCredentials
        }

        print("👤 Service: Verifying code \(code) with ID \(verificationID)...")
        // Guarda el código verificado en el servicio si es necesario
        self.verificationCode = code

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code // Usa el parámetro code
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            print("✅ Service: Phone authentication successful! User UID: \(authResult.user.uid)")
            UserDefaults.standard.removeObject(forKey: "verificationID_async")
        } catch let error {
            print("❌ Service: Phone sign in failed: \(error.localizedDescription)")
            throw ServiceError.authenticationError(error)
        }
    }

    // MARK: - Private Async Helpers
    
    private func saveSignupAttemptAsync() async throws {
        guard let url = URL(string: "\(self.baseURL)/users/signup_events") else { throw ServiceError.invalidURL }
        let request = try createJsonRequest(url: url, method: "POST", bodyJson: [:])
        let (data, httpResponse) = try await performRequest(request: request)
        guard (200...299).contains(httpResponse.statusCode) else {
                let bodyString = String(data: data, encoding: .utf8)
                throw ServiceError.backendRegistrationFailed(statusCode: httpResponse.statusCode,
                                                             message: bodyString)
            }
    
        do {
            // 1) Parsear JSON crudo
            guard let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String:Any] else {
                throw ServiceError.invalidURL
            }

            // 2) Extraer rawValue (puede venir como Int o String)
            guard let rawId = jsonObj["attempt_id"] else {
                throw ServiceError.invalidURL
            }

            // 3) Convertir a String
            let attemptId: String
            if let intVal = rawId as? Int {
                attemptId = String(intVal)
            } else if let strVal = rawId as? String {
                attemptId = strVal
            } else {
                throw ServiceError.invalidURL
            }

            // 4) Eliminar cualquier intento previo
            if let old = UserDefaults.standard.string(forKey: "signupAttemptId") {
                print("Eliminando intento previo: \(old)")
                UserDefaults.standard.removeObject(forKey: "signupAttemptId")
            }

            // 5) Guardar el nuevo attemptId
            UserDefaults.standard.set(attemptId, forKey: "signupAttemptId")
            print("Nuevo attemptId guardado: \(attemptId)")

        } catch {
            print("Error manejando attempt_id:", error)
        }

    }

    private func registerUserInBackendAsync(name: String, email: String, phoneNumber: String, areaId: Int, userType: String, verificationCode: String) async throws {
         guard let url = URL(string: "\(self.baseURL)/users") else { throw ServiceError.invalidURL }
         let userPayload: [String: Any] = [
             "name": name, "user_email": email, "mobile_number": phoneNumber,
             "area_id": areaId, "verification_code": verificationCode,
             "user_type": userType, "attempt_id": UserDefaults.standard.string(forKey: "signupAttemptId") ?? ""
         ]
         print("🌐 Service: Sending user data to backend \(url)...")

         let request = try createJsonRequest(url: url, method: "POST", bodyJson: userPayload)
         let (data, httpResponse) = try await performRequest(request: request)

         guard (200...299).contains(httpResponse.statusCode) else {
              let responseBody = String(data: data, encoding: .utf8)
             print("❌ Service: Backend registration failed. Status: \(httpResponse.statusCode), Body: \(responseBody ?? "N/A")")
            throw ServiceError.backendRegistrationFailed(statusCode: httpResponse.statusCode, message: responseBody)
         }
         print("✅ Service: Backend user registration successful (Status: \(httpResponse.statusCode)).")
    }

    private func registerUserInFirebaseAsync(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else { throw ServiceError.missingCredentials }
         print("🔥 Service: Creating user in Firebase for \(email)...")
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Service: Firebase user created successfully! UID: \(authResult.user.uid)")
        } catch let error {
            print("❌ Service: Firebase signup failed: \(error.localizedDescription)")
            throw ServiceError.authenticationError(error)
        }
    }

    // MARK: - Helpers

    private func createJsonRequest(url: URL, method: String, bodyJson: [String: Any]? = nil) throws -> URLRequest {
         var request = URLRequest(url: url)
         request.httpMethod = method
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         if let body = bodyJson {
             do { request.httpBody = try JSONSerialization.data(withJSONObject: body, options: []) }
             catch { throw ServiceError.serializationError(error) }
         }
         return request
    }

    private func performRequest(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
         do {
             let (data, response) = try await URLSession.shared.data(for: request)
             guard let httpResponse = response as? HTTPURLResponse else { throw ServiceError.badServerResponse(statusCode: -1) }
             print("📬 [\(request.httpMethod ?? "")] \(request.url?.absoluteString ?? "") -> Status: \(httpResponse.statusCode)")
             return (data, httpResponse)
         } catch {
             print("❌ Network Error for \(request.url?.absoluteString ?? ""): \(error)")
             throw ServiceError.requestFailed(error)
         }
    }
}
