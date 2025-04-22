//
//  WelcomeController.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation
import Combine 

class WelcomeController: ObservableObject {

    // MARK: - Published State
    @Published var showSignupView: Bool = false
    @Published var showSignInView: Bool = false

    // MARK: - Initialization
    init() {
        print("👋 WelcomeController initialized.")
    }

    // MARK: - Public Actions (Navigation Triggers)

    /// Indica la intención de navegar al flujo de Signup.
    func navigateToSignup() {
        print("▶️ User wants to navigate to Signup.")
        showSignupView = true // La vista reaccionará a este cambio
    }

    /// Indica la intención de navegar al flujo de Signin.
    func navigateToSignin() {
        print("▶️ User wants to navigate to Signin.")
        showSignInView = true // La vista reaccionará a este cambio
    }
}
