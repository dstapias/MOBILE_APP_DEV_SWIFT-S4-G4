//
//  SignInUserService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation
import FirebaseAuth

class SignInUserService: ObservableObject {
    static let shared = SignInUserService() // ✅ Singleton instance

    @Published var email: String? = nil
    @Published var password: String? = nil
    @Published var errorMessage: String = ""

    private init() {}

    // ✅ Firebase Authentication: Sign-in Function
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
                completion(.success(()))
            }
        }
    }

    // ✅ Firebase Authentication: Password Reset
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
}
