import SwiftUI

struct SignInView: View {
    // Estados controlados por la vista padre (para mostrar/ocultar y estado global de login)
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. El controlador es la fuente principal de estado y lógica para esta vista
    @StateObject private var controller: SignInController

    // Estado local solo para UI (visibilidad contraseña)
    @State private var isPasswordVisible: Bool = false
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""


    // 2. Inicializador (opcional, si necesitas inyectar algo al controller)
    //    Si SignInController usa SignInUserService.shared, no necesitas un init especial.
    init(showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
            // Asigna bindings
            self._showSignInView = showSignInView
            self._isLoggedIn = isLoggedIn

            // 1. Crea la instancia del Repositorio
            //    (APIAuthRepository necesita ambos servicios en su init)
            let authRepository = APIAuthRepository(
                signInService: SignInUserService.shared,
                signupService: SignupUserService.shared
            )

            // 2. Crea el Controller inyectando el Repositorio
            let signInController = SignInController(authRepository: authRepository)

            // 3. Asigna al StateObject wrapper
            self._controller = StateObject(wrappedValue: signInController)
            print("🔑 SignInView initialized and injected AuthRepository into Controller.")
        }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Botón de volver (sin cambios)
                HStack {
                    Button(action: { showSignInView = false }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }

                Spacer() // Centrar

                VStack(alignment: .leading, spacing: 10) {
                    // Títulos (sin cambios)
                    Text("Sign-in")
                        .font(.title).bold()
                    Text("Enter your email and password")
                        .font(.footnote).foregroundColor(.gray)

                    // --- Email Input ---
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.footnote).foregroundColor(.gray)
                        // 3. Bindea directamente al controller
                        TextField("Enter your email", text: $emailInput)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.bottom, 5)
                            .onChange(of: emailInput) { newValue in
                                if newValue.count <= 50 {
                                    controller.email = newValue
                                } else {
                                    let trimmed = String(newValue.prefix(50))
                                    emailInput = trimmed
                                    controller.email = trimmed
                                }
                            }
                        Divider()
                    }

                    // --- Password Input ---
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .font(.footnote).foregroundColor(.gray)
                        HStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $passwordInput)
                            } else {
                                SecureField("Enter your password", text: $passwordInput)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: passwordInput) { newValue in
                            if newValue.count <= 50 {
                                controller.password = newValue
                            } else {
                                let trimmed = String(newValue.prefix(50))
                                passwordInput = trimmed
                                controller.password = trimmed
                            }
                        }
                        .padding(.bottom, 5)
                        Divider()
                    }

                    // --- Forgot Password Button ---
                    HStack {
                        Spacer()
                        Button(action: {
                            // 4. Llama directamente al método del controller
                            controller.resetPassword()
                        }) {
                            Text("Forgot Password?")
                                .font(.footnote).foregroundColor(.gray)
                        }
                    }

                    // --- Firebase Login Button ---
                    Button(action: {
                        // 4. Llama directamente al método del controller
                        controller.signInUser()
                    }) {
                        // 5. Usa el estado isLoading del controller
                        if controller.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white)) // Tint para contraste
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.gray) // Gris mientras carga
                                .cornerRadius(10)
                        } else {
                            Text("Log-in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                    // Deshabilitar si está cargando
                    .disabled(controller.isLoading)
                    if let errorMessage = controller.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    } else if let successMessage = controller.successMessage {
                         Text(successMessage)
                            .font(.footnote)
                            .foregroundColor(.green) // Verde para éxito
                            .padding(.top, 5)
                    }

                } // Fin VStack de Inputs
                .padding(.horizontal, 30)
                .frame(maxWidth: geometry.size.width * 0.9)

                Spacer()

            } // Fin VStack principal
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                    emailInput = controller.email
                    passwordInput = controller.password
            }
            // 7. Reacciona al cambio de estado de éxito del controller
            .onChange(of: controller.didSignInSuccessfully) { newValue in
                 if newValue {
                     print("🔑 SignInView detected successful sign in via controller.")
                     // Actualiza el estado de la vista padre para navegar/cerrar
                     isLoggedIn = true
                     showSignInView = false
                 }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true), isLoggedIn: .constant(false))
             .environmentObject(SignInUserService.shared)
    }
}
