import SwiftUI

struct PhoneNumberView: View {
    @Binding var showPhoneNumberView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. Controller como StateObject
    @StateObject private var controller: PhoneNumberController

    // 2. FocusState se mantiene
    @FocusState private var isPhoneNumberFocused: Bool

    // 5. Inicializador
    init(showPhoneNumberView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
        // 1. Crear instancia del Repositorio
        let authRepository = APIAuthRepository(
            signInService: .shared,
            signupService: .shared
        )

        // 2. Crear el Controller inyectando el Repositorio
        let phoneController = PhoneNumberController(authRepository: authRepository)

        // 3. Asignar al StateObject wrapper
        self._controller = StateObject(wrappedValue: phoneController)

        self._showPhoneNumberView = showPhoneNumberView
        self._showSignInView = showSignInView
        self._isLoggedIn = isLoggedIn

        print("📞 PhoneNumberView initialized and injected AuthRepository into Controller.")
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                HStack {
                     Button(action: { showPhoneNumberView = false }) {
                         Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                     }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                 }
                .frame(maxWidth: .infinity)

                Text("Enter your mobile number")
                    .font(.title).bold()
                    .padding(.horizontal, 20).padding(.top, 20)

                // --- Input de Teléfono ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number").font(.footnote).foregroundColor(.gray)
                    HStack {
                        Image("colombia_flag")
                            .resizable().scaledToFit().frame(width: 20, height: 14)
                        Text("+57").font(.headline)

                        // 6. TextField bindeado a controller.rawPhoneNumber
                        TextField("300 123 4567", text: $controller.rawPhoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .focused($isPhoneNumberFocused)
                            .frame(height: 40)
                            .padding(.leading, 5)
                            .background(Color.clear)
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
                    if controller.isLoading {
                         ProgressView()
                            .frame(width: 44, height: 44)
                            .background(Color.gray)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding()
                            .background(controller.isPhoneNumberValid ? Color.green : Color.gray)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20).padding(.bottom, 20)
                .disabled(!controller.isPhoneNumberValid || controller.isLoading)

            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("Phone Number")
            .onAppear {
                isPhoneNumberFocused = true
            }
            .fullScreenCover(isPresented: $controller.showFourDigitCodeView) {
                FourDigitCodeView(showFourDigitCodeView: $controller.showFourDigitCodeView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

struct PhoneNumberView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberView(
            showPhoneNumberView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
        .environmentObject(SignupUserService.shared)
    }
}
