import SwiftUI

struct FourDigitCodeView: View {
    // Bindings para control parental (sin cambios)
    @Binding var showFourDigitCodeView: Bool
    @Binding var showSignInView: Bool // Sigue siendo necesario para pasarlo a LocationView
    @Binding var isLoggedIn: Bool

    // 1. Usa StateObject para el nuevo Controller
    @StateObject private var controller: FourDigitCodeController

    // 2. FocusState se mantiene en la Vista
    @FocusState private var isCodeFocused: Bool

    // 3. El servicio ya no se observa directamente aquí
    // @ObservedObject var userService = SignupUserService.shared // ELIMINADO

    // 4. Estado local de UI (isLoading, errorMessage, showLocationView) ELIMINADO

    // 5. Inicializador
    init(showFourDigitCodeView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
        self._showFourDigitCodeView = showFourDigitCodeView
        self._showSignInView = showSignInView
        self._isLoggedIn = isLoggedIn

        // 1. Crear instancia del Repositorio
        let authRepository = APIAuthRepository(
            signInService: .shared, // Asume que APIAuthRepository los necesita
            signupService: .shared
        )

        // 2. Crear el Controller inyectando el Repositorio
        let codeController = FourDigitCodeController(authRepository: authRepository)

        // 3. Asignar al StateObject wrapper
        self._controller = StateObject(wrappedValue: codeController)
        print("🔢 FourDigitCodeView initialized and injected AuthRepository into Controller.")
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // Botón de volver (sin cambios)
                HStack {
                    Button(action: { showFourDigitCodeView = false }) {
                         Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                     }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                 }
                .frame(maxWidth: .infinity)

                // Título (sin cambios)
                Text("Enter your 6-digit code")
                    .font(.title).bold()
                    .padding(.horizontal, 20).padding(.top, 20)

                // --- Input de Código ---
                VStack {
                    // 6. Display del código (lee del controller)
                    HStack(spacing: 15) {
                        ForEach(0..<6, id: \.self) { index in
                            Text(controller.verificationCode.count > index ? "•" : "_")
                                .font(.largeTitle)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    // 7. TextField oculto bindeado al controller
                    TextField("", text: $controller.verificationCode)
                        .keyboardType(.numberPad)
                        .focused($isCodeFocused) // Control de foco (sin cambios)
                        .textContentType(.oneTimeCode) // Ayuda al autocompletado (sin cambios)
                        .frame(width: 1, height: 1).opacity(0.01) // Oculto (sin cambios)
                        // 8. El .onChange para limitar longitud ya no es necesario aquí (lo hace el controller)
                        .onAppear { isCodeFocused = true } // Abre teclado (sin cambios)

                } // Fin VStack Input
                .frame(maxWidth: .infinity, alignment: .center)

                // Muestra errores del controller
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }


                Spacer() // Empuja el botón hacia abajo

                // --- Botón Siguiente/Verificar ---
                Button(action: {
                    // 9. Llama a la acción del controller
                    controller.verifyCode()
                }) {
                    // 10. Muestra ProgressView basado en controller.isLoading
                    if controller.isLoading {
                        ProgressView()
                            .frame(width: 44, height: 44) // Tamaño similar al círculo
                            .background(Color.gray) // Fondo mientras carga
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding()
                             // 11. Color basado en controller.isCodeComplete
                            .background(controller.isCodeComplete ? Color.green : Color.gray)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20).padding(.bottom, 20)
                 // 12. Estado disabled basado en controller
                .disabled(!controller.isCodeComplete || controller.isLoading)

            } // Fin VStack principal
            .navigationBarBackButtonHidden(false) // ¿Seguro que quieres esto si tienes botón custom?
            .navigationTitle("6 Digit Code") // Título de navegación
            // 13. fullScreenCover usa el estado del controller
            .fullScreenCover(isPresented: $controller.showLocationView) {
                 // Pasa los bindings necesarios a la siguiente vista
                 LocationView(showLocationView: $controller.showLocationView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        } // Fin GeometryReader
    } // Fin body
} // Fin struct FourDigitCodeView

// --- Preview ---
struct FourDigitCodeView_Previews: PreviewProvider {
    static var previews: some View {
        // Necesita los bindings para la preview
        FourDigitCodeView(
            showFourDigitCodeView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
         // Necesita el servicio si el controller lo usa implícitamente
        .environmentObject(SignupUserService.shared)
    }
}
