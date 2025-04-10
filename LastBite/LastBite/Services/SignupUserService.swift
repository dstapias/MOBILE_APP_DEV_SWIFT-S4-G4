//
//  SignupUserService.swift
//  LastBite
//
//  Created by David Santiago on 11/03/25.
//

import Foundation
import FirebaseAuth

class SignupUserService: ObservableObject {
    static let shared = SignupUserService() // ✅ Singleton instance

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var selectedAreaId: Int?
    @Published var verificationCode: String = ""
    @Published var userType: String = ""
    @Published var password: String = ""

    private let baseURL = Constants.baseURL // ✅ Use centralized backend URL

    private init() {}

    // ✅ Function to handle Backend Registration first, then Firebase Authentication
    func registerUser(completion: @escaping (Result<String, Error>) -> Void) {
        guard let areaId = selectedAreaId else {
            completion(.failure(NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Area ID is missing"])))
            return
        }

        // ✅ First, Send Data to Backend
        let userPayload: [String: Any] = [
            "name": self.name,
            "user_email": self.email,
            "mobile_number": self.phoneNumber,
            "area_id": areaId, // ✅ Use `areaId` from `guard let`
            "verification_code": self.verificationCode,
            "user_type": self.userType,
        ]

        guard let url = URL(string: "\(self.baseURL)/users") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userPayload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "HTTP Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "No response from server"])))
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Backend registration successful! Proceeding to Firebase signup...")
                
                // ✅ Now, Create User in Firebase
                self.registerUserInFirebase { firebaseResult in
                    switch firebaseResult {
                    case .success:
                        completion(.success("User registered successfully in backend and Firebase!"))
                    case .failure(let firebaseError):
                        completion(.failure(firebaseError)) // ✅ If Firebase fails, return the error
                    }
                }

            default:
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Backend error: \(httpResponse.statusCode)"])))
            }
        }.resume()
    }

    // ✅ Function to register user in Firebase AFTER backend registration
    private func registerUserInFirebase(completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Firebase signup failed:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            print("✅ Firebase user created successfully!")
            completion(.success(()))
        }
    }
    func sendVerificationCode(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !phoneNumber.isEmpty else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Phone number is missing"])))
            return
        }

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error as NSError? {
                print("❌ Firebase Error:", error.localizedDescription)
                print("❌ Firebase Error Code:", error.code)
                print("❌ Firebase Error UserInfo:", error.userInfo)
                completion(.failure(error))
                return
            }

            guard let verificationID = verificationID else {
                completion(.failure(NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain verification ID"])))
                return
            }

            UserDefaults.standard.set(verificationID, forKey: "verificationID")
            print("✅ Código enviado correctamente a \(self.phoneNumber)")
            completion(.success(()))
        }
    }
    
    // Function to verify the SMS code using Firebase
    func verifyCode(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "verificationID") else {
            completion(.failure(NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Verification ID not found"])))
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            print("✅ Phone authentication successful!")
            
            // Optionally, fetch the Firebase ID token
            Auth.auth().currentUser?.getIDToken { token, error in
                if let token = token {
                    print("Firebase ID Token: \(token)")
                } else if let error = error {
                    print("Error fetching token: \(error.localizedDescription)")
                }
            }
            
            completion(.success(()))
        }
    }
}
