import SwiftUI

struct FourDigitCodeView: View {
    @Binding var showFourDigitCodeView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. Usa StateObject para el nuevo Controller
    @StateObject private var controller: FourDigitCodeController

    // 2. FocusState se mantiene en la Vista
    @FocusState private var isCodeFocused: Bool

    // 5. Inicializador
    init(showFourDigitCodeView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
        self._showFourDigitCodeView = showFourDigitCodeView
        self._showSignInView = showSignInView
        self._isLoggedIn = isLoggedIn

        // 1. Crear instancia del Repositorio
        let authRepository = APIAuthRepository(
            signInService: .shared,
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

                Text("Enter your 6-digit code")
                    .font(.title).bold()
                    .padding(.horizontal, 20).padding(.top, 20)

                // --- Input de Código ---
                VStack {
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
                        .focused($isCodeFocused)
                        .textContentType(.oneTimeCode)
                        .frame(width: 1, height: 1).opacity(0.01)
                        .onAppear { isCodeFocused = true }

                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Muestra errores del controller
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }


                Spacer()

                Button(action: {
                    controller.verifyCode()
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
                             // 11. Color basado en controller.isCodeComplete
                            .background(controller.isCodeComplete ? Color.green : Color.gray)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20).padding(.bottom, 20)
                 // 12. Estado disabled basado en controller
                .disabled(!controller.isCodeComplete || controller.isLoading)

            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("6 Digit Code")
            .fullScreenCover(isPresented: $controller.showLocationView) {
                 LocationView(showLocationView: $controller.showLocationView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

struct FourDigitCodeView_Previews: PreviewProvider {
    static var previews: some View {
        FourDigitCodeView(
            showFourDigitCodeView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
        .environmentObject(SignupUserService.shared)
    }
}
