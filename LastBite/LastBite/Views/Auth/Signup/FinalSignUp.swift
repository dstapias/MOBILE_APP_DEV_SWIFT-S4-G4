import SwiftUI

struct FinalSignUpView: View {
    // Bindings para control parental (sin cambios)
    @Binding var showFinalSignUpView: Bool
    @Binding var isLoggedIn: Bool
    // showSignInView se usa en la navegación final

    // 1. Controller como StateObject
    @StateObject private var controller: FinalSignupController

    // 2. Estado local solo para UI (visibilidad contraseña)
    @State private var isPasswordVisible: Bool = false
    
    // 5. Inicializador
    init(showFinalSignUpView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
       self._showFinalSignUpView = showFinalSignUpView
       self._isLoggedIn = isLoggedIn

       let controller = Self.createController()
       self._controller = StateObject(wrappedValue: controller)
       print("✅ FinalSignUpView: Controller initialized from safe context.")
    }
    @MainActor
    private static func createController() -> FinalSignupController {
       let authRepo = APIAuthRepository(
           signInService: .shared,
           signupService: .shared
       )
       let userService = SignupUserService.shared
       return FinalSignupController(authRepository: authRepo, signupStateService: userService)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 15) {

                // Botón Volver (sin cambios)
                HStack {
                     Button(action: { showFinalSignUpView = false }) { // Cierra esta vista modal
                         Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                     }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                 }
                .frame(maxWidth: .infinity)

                Spacer()

                // Títulos (sin cambios)
                Text("Sign-up").font(.title).bold()
                Text("Enter your credentials to continue").font(.footnote).foregroundColor(.gray)

                // --- Name Input ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Full Name").font(.footnote).foregroundColor(.gray)
                    // 6. Bindea al controller
                    TextField("Enter your name", text: $controller.name)
                        .autocapitalization(.words)
                        .padding(.bottom, 5)
                    Divider()
                }

                // --- Email Input ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email").font(.footnote).foregroundColor(.gray)
                    // 6. Bindea al controller
                    TextField("Enter your email", text: $controller.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 5)
                    Divider()
                }
                // 7. Muestra error de formato de email basado en controller
                if !controller.isEmailValid && !controller.email.isEmpty {
                    Text("Invalid email format")
                        .font(.caption).foregroundColor(.red) // Usar caption es más pequeño
                }

                // --- Password Input ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password").font(.footnote).foregroundColor(.gray)
                    HStack {
                         if isPasswordVisible {
                             // 6. Bindea al controller
                             TextField("Enter your password", text: $controller.password)
                         } else {
                              // 6. Bindea al controller
                             SecureField("Enter your password", text: $controller.password)
                         }
                         Button(action: { isPasswordVisible.toggle() }) {
                             Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                 .foregroundColor(.gray)
                         }
                     }
                    .padding(.bottom, 5)
                    Divider()
                }
                 // 7. Muestra error de longitud de contraseña basado en controller
                 if !controller.isPasswordValid && !controller.password.isEmpty {
                     Text("Password must be at least 6 characters")
                         .font(.caption).foregroundColor(.red)
                 }

                // Texto legal (sin cambios)
                Text("By continuing you agree to our **Terms of Service** and **Privacy Policy**.")
                    .font(.footnote).foregroundColor(.gray).padding(.top, 5)

                Button(action: {
                    controller.registerUser()
                }) {
                    ZStack {
                        if controller.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit").font(.headline).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(!controller.isFormValid || controller.isLoading ? Color.gray : Color.green)
                    .cornerRadius(10)
                     .opacity(!controller.isFormValid || controller.isLoading ? 0.6 : 1.0)
                }
                .padding(.top, 10)
                .disabled(!controller.isFormValid || controller.isLoading)

                if let error = controller.errorMessage {
                    Text(error)
                        .font(.footnote).foregroundColor(.red).padding(.top, 5)
                }

                Spacer()

                HStack {
                    Text("Already have an account?")
                        .font(.footnote).foregroundColor(.gray)
                    Button(action: {
                        controller.goToSignIn()
                    }) {
                        Text("Sign-in")
                            .font(.footnote).foregroundColor(.green).bold()
                    }
                }
                .padding(.bottom, 20)

            }
            .padding(.horizontal, 30)


        }
        .alert("Success", isPresented: $controller.showSuccessMessage) {
             Button("OK") {
                 controller.goToSignIn()
             }
        } message: {
             Text("User created successfully!")
        }
        .fullScreenCover(isPresented: $controller.navigateToSignIn) {
            SignInView(
                showSignInView: $controller.navigateToSignIn,
                isLoggedIn: $isLoggedIn
            )
        }
        .onAppear {
        }

    }
}

struct FinalSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        FinalSignUpView(
            showFinalSignUpView: .constant(true),
            isLoggedIn: .constant(false)
        )
       .environmentObject(SignupUserService.shared)
    }
}
