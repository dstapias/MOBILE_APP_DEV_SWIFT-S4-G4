import SwiftUI

struct SignupView: View {
    @Binding var showSignupView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    @StateObject private var controller: SignupController

        init(showSignupView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
            self._showSignupView = showSignupView
            self._showSignInView = showSignInView
            self._isLoggedIn = isLoggedIn

            // 1. Crea la instancia del Repositorio pasándole los servicios
            let authRepository = APIAuthRepository(
                signInService: SignInUserService.shared,
                signupService: SignupUserService.shared
            )

            // 2. Crea el Controller CORRECTO (SignupController) inyectando el Repositorio
            let signupController = SignupController(authRepository: authRepository)

            // 3. Asigna al StateObject wrapper
            self._controller = StateObject(wrappedValue: signupController)
            print("👋 SignupView initialized and injected AuthRepository into Controller.")
        }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Button(action: { showSignupView = false }) {
                        Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                    }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: geometry.size.height * 0.05)

                Image("bag_of_fruits")
                    .resizable().scaledToFit()
                    .frame(width: min(219, geometry.size.width * 0.5), height: min(384, geometry.size.height * 0.35))
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Get cheap food")
                         .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular))
                    Text("with LastBite")
                         .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40).padding(.top, 10)

                // Botón para iniciar flujo de teléfono
                Button(action: {
                    // 3. Llama a la acción del controller
                    controller.startPhoneNumberSignup()
                }) {
                    HStack {
                         Image("colombia_flag")
                            .resizable().scaledToFit().frame(width: 20, height: 14)
                         Text("+57").font(.headline)
                         Spacer()
                     }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.horizontal, 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 10)

                Divider().padding(.horizontal, 40)

                Text("Or connect with social media")
                    .font(.footnote).foregroundColor(.gray)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Botones Sociales
                VStack(spacing: 15) {
                    socialButton(image: "google_login", text: "Continue with Google", color: Color.blue) {
                        controller.signInWithGoogle()
                    }
                    socialButton(image: "facebook_login", text: "Continue with Facebook", color: Color.blue.opacity(0.8)) {
                         controller.signInWithFacebook()
                    }
                }
                .frame(maxWidth: min(500, geometry.size.width * 0.8))
                .padding(.top, 20)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding()
            .fullScreenCover(isPresented: $controller.showPhoneNumberView) {
                 PhoneNumberView(showPhoneNumberView: $controller.showPhoneNumberView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        }
    }

    private func socialButton(image: String, text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { // <--- Usa la acción pasada
            HStack {
                Image(image)
                    .resizable().scaledToFit().frame(width: 22, height: 22)
                Spacer().frame(width: 12)
                Text(text)
                    .bold().frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(.horizontal, 20)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}


