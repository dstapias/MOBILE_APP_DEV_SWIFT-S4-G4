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

    // 3. El servicio ya no se observa directamente aquí
    // @ObservedObject var userService = SignupUserService.shared // ELIMINADO

    // 4. Estados locales de carga/error/navegación ELIMINADOS

    // 5. Inicializador
    init(showFinalSignUpView: Binding<Bool>, isLoggedIn: Binding<Bool>) { // Mantiene sus bindings
        self._showFinalSignUpView = showFinalSignUpView
        self._isLoggedIn = isLoggedIn

        // 1. Crear instancia del Repositorio
        let authRepository = APIAuthRepository(
            signInService: .shared, // APIAuthRepository necesita ambos servicios
            signupService: .shared
        )

        // 2. Crear el Controller inyectando el Repositorio
        //    (No necesita pasar signupStateService explícitamente si el controller usa el singleton)
        let finalController = FinalSignupController(authRepository: authRepository)

        // 3. Asignar al StateObject wrapper
        self._controller = StateObject(wrappedValue: finalController)
        print("✅ FinalSignUpView initialized and injected AuthRepository into Controller.")
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

                // --- Submit Button ---
                Button(action: {
                    // 8. Llama a la acción del controller
                    controller.registerUser()
                }) {
                    ZStack {
                        // 9. Muestra ProgressView basado en controller.isLoading
                        if controller.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit").font(.headline).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    // 10. Estado disabled/color basado en controller
                    .background(!controller.isFormValid || controller.isLoading ? Color.gray : Color.green)
                    .cornerRadius(10)
                     // Opcional: Opacidad para feedback visual
                     .opacity(!controller.isFormValid || controller.isLoading ? 0.6 : 1.0)
                }
                .padding(.top, 10)
                 // 10. Estado disabled basado en controller
                .disabled(!controller.isFormValid || controller.isLoading)

                // --- Mensaje de Error General del Controller ---
                if let error = controller.errorMessage {
                    Text(error)
                        .font(.footnote).foregroundColor(.red).padding(.top, 5)
                }

                Spacer() // Empuja link de Sign-in hacia abajo

                // --- Sign-in Redirect ---
                HStack {
                    Text("Already have an account?")
                        .font(.footnote).foregroundColor(.gray)
                    Button(action: {
                        // 11. Llama a la acción del controller para navegar
                        controller.goToSignIn()
                    }) {
                        Text("Sign-in")
                            .font(.footnote).foregroundColor(.green).bold()
                    }
                }
                .padding(.bottom, 20)

            } // Fin VStack principal
            .padding(.horizontal, 30)
             // Quitado frame maxWidth para permitir centrado natural
             // .frame(maxWidth: geometry.size.width * 0.9) // Esto podría no ser necesario

        } // Fin GeometryReader
        // 12. Alert de éxito bindeado al controller
        .alert("Success", isPresented: $controller.showSuccessMessage) {
             Button("OK") {
                 // Llama al método del controller al cerrar el alert
                 controller.goToSignIn()
             }
        } message: {
             Text("User created successfully!")
        }
         // 13. fullScreenCover para navegar a SignIn bindeado al controller
         //    Nota: Necesita el binding $isLoggedIn que viene de la vista padre
        .fullScreenCover(isPresented: $controller.navigateToSignIn) {
            // Cierra esta vista primero ANTES de mostrar SignIn
            // Esto se maneja cambiando el estado que presentó esta vista
            // La forma más limpia es que el Coordinator/VistaPadre observe el cambio
            // en isLoggedIn o un estado similar y cambie la vista principal.
            // Presentar SignInView directamente aquí puede llevar a jerarquías complejas.

            // Solución Simple (puede dar warnings de jerarquía):
             SignInView(showSignInView: $controller.navigateToSignIn, isLoggedIn: $isLoggedIn)
                .onAppear {
                     // Cierra esta vista (FinalSignUpView) una vez que SignInView aparece
                     // Esto asume que showFinalSignUpView es el binding correcto que controla ESTA vista
                     showFinalSignUpView = false
                 }
        }
         .onAppear {
             // 14. Lógica de onAppear (setear userType) movida al Controller si fuera necesario,
             //     o se puede quedar aquí si es específico de la inicialización de la vista.
             //     Pero como modifica userService, mejor en el controller o al inicio del flujo.
             // userService.userType = Constants.USER_TYPE_CUSTOMER // Ya no se accede directamente
             // Si necesitas esto, haz que el controller lo haga en su init o en una función.
         }
         // 15. Funciones isValidEmail, validateFields ELIMINADAS de la vista
         // 16. Propiedad computada isSubmitDisabled ELIMINADA de la vista

    } // Fin body
} // Fin struct FinalSignUpView

// --- Preview ---
struct FinalSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        FinalSignUpView(
            showFinalSignUpView: .constant(true),
            // showSignInView: .constant(false), // Este binding no parece usarse aquí
            isLoggedIn: .constant(false)
        )
        // Necesita el servicio si el controller lo usa implícitamente
       .environmentObject(SignupUserService.shared)
    }
}
