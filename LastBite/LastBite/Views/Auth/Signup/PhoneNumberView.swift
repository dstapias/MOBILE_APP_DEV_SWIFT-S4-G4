import SwiftUI

struct PhoneNumberView: View {
    // Bindings para control parental (sin cambios)
    @Binding var showPhoneNumberView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. Controller como StateObject
    @StateObject private var controller: PhoneNumberController

    // 2. FocusState se mantiene
    @FocusState private var isPhoneNumberFocused: Bool

    // 3. El servicio ya no se observa/usa directamente aquí
    // @ObservedObject var userService = SignupUserService.shared // ELIMINADO

    // 4. Estado local para navegación ELIMINADO (@State showFourDigitCodeView)

    // 5. Inicializador
    init(showPhoneNumberView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
        self._showPhoneNumberView = showPhoneNumberView
        self._showSignInView = showSignInView
        self._isLoggedIn = isLoggedIn
        // Crea el controller (asume que usa el singleton del servicio)
        self._controller = StateObject(wrappedValue: PhoneNumberController())
        print("📞 PhoneNumberView initialized.")
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // Botón Volver (sin cambios)
                HStack {
                     Button(action: { showPhoneNumberView = false }) {
                         Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                     }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                 }
                .frame(maxWidth: .infinity)

                // Título (sin cambios)
                Text("Enter your mobile number")
                    .font(.title).bold()
                    .padding(.horizontal, 20).padding(.top, 20)

                // --- Input de Teléfono ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number").font(.footnote).foregroundColor(.gray)
                    HStack {
                        Image("colombia_flag") // Asume que esta imagen existe
                            .resizable().scaledToFit().frame(width: 20, height: 14)
                        Text("+57").font(.headline)

                        // 6. TextField bindeado a controller.rawPhoneNumber
                        TextField("300 123 4567", text: $controller.rawPhoneNumber) // Placeholder opcional
                            .keyboardType(.numberPad) // Teclado numérico
                            .textContentType(.telephoneNumber) // Ayuda autocompletado
                            .focused($isPhoneNumberFocused) // Control de foco
                            .frame(height: 40)
                            .padding(.leading, 5)
                            .background(Color.clear)
                            // 7. El .onChange para formato/longitud se elimina (lo hace el controller)
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20).padding(.top, 10)

                 // Muestra errores del controller
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                }

                Spacer() // Empuja botón hacia abajo

                // --- Botón Siguiente ---
                Button(action: {
                    // 8. Llama a la acción del controller
                    controller.sendVerificationCode()
                }) {
                     // 9. Muestra ProgressView basado en controller.isLoading
                    if controller.isLoading {
                         ProgressView()
                            .frame(width: 44, height: 44)
                            .background(Color.gray)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding()
                            // 10. Color basado en controller.isPhoneNumberValid
                            .background(controller.isPhoneNumberValid ? Color.green : Color.gray)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20).padding(.bottom, 20)
                 // 11. Estado disabled basado en controller
                .disabled(!controller.isPhoneNumberValid || controller.isLoading)

            } // Fin VStack principal
            .navigationBarBackButtonHidden(false) // Revisar si es necesario
            .navigationTitle("Phone Number") // Título de navegación
            .onAppear {
                isPhoneNumberFocused = true // Abre teclado al aparecer
            }
            // 12. fullScreenCover usa el estado del controller
            .fullScreenCover(isPresented: $controller.showFourDigitCodeView) {
                 // Pasa los bindings necesarios a la siguiente vista
                 // Nota: FourDigitCodeView también debería ser refactorizada si no lo has hecho
                FourDigitCodeView(showFourDigitCodeView: $controller.showFourDigitCodeView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        } // Fin GeometryReader
    } // Fin body
} // Fin struct PhoneNumberView

// --- Preview ---
struct PhoneNumberView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberView(
            showPhoneNumberView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
         // Necesita el servicio si el controller lo usa implícitamente
        .environmentObject(SignupUserService.shared)
    }
}
