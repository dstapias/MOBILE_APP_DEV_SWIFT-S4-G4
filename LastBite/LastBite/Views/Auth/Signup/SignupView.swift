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
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: { showSignupView = false }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top) // only here
                .frame(maxWidth: .infinity)

                Image("bag_of_fruits")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: min(219, geometry.size.width * 0.5),
                        height: min(384, geometry.size.height * 0.35)
                    )
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Get cheap food")
                        .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular))
                    Text("with LastBite")
                        .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular))
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                Button(action: {
                    controller.startPhoneNumberSignup()
                }) {
                    HStack {
                        Image("colombia_flag")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 14)
                        Text("+57").font(.headline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.horizontal, 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 10)

                Spacer()
            }
            .ignoresSafeArea(edges: .top) // <- allows going into safe area
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .fullScreenCover(isPresented: $controller.showPhoneNumberView) {
            PhoneNumberView(
                showPhoneNumberView: $controller.showPhoneNumberView,
                showSignInView: $showSignInView,
                isLoggedIn: $isLoggedIn
            )
        }
    }

}


