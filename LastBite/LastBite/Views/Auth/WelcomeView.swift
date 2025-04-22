import SwiftUI

struct WelcomeView: View {
    @StateObject private var controller = WelcomeController()
    @Binding var isLoggedIn: Bool

    var body: some View {
        GeometryReader { geometry in 
            ZStack {
                // Fondo
                Image("WelcomeImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    // Hacemos que la imagen intente llenar el espacio dado por GeometryReader
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack {
                    Spacer(minLength: geometry.size.height * 0.1)
                    Text("Welcome to our store")
                        .font(.system(size: min(geometry.size.width * 0.08, 36)))
                        .bold().foregroundColor(.white).multilineTextAlignment(.center)
                        .padding(.horizontal, 20).background(Color.black.opacity(0.5)).cornerRadius(10)
                    Text("Get your food cheaper than anywhere")
                        .font(.subheadline).foregroundColor(.white.opacity(0.9))
                        .padding(.top, 5).padding(.horizontal, 30).background(Color.black.opacity(0.5))

                    Spacer()

                    Button(action: controller.navigateToSignup) {
                        Text("Go to Signup")
                            .font(.headline).foregroundColor(.white).padding()
                            .frame(width: min(geometry.size.width * 0.7, 300))
                            .background(Color.primaryGreen).cornerRadius(10)
                    }
                    .padding(.bottom, 20)

                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline).foregroundColor(.white)
                        Button(action: controller.navigateToSignin) {
                            Text("Sign-in")
                                .font(.subheadline).foregroundColor(.green).bold()
                        }
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))

                }
                .padding()

            }

        }
        .ignoresSafeArea()

       .fullScreenCover(isPresented: $controller.showSignupView) {
            SignupView(
                showSignupView: $controller.showSignupView,
                showSignInView: $controller.showSignInView,
                isLoggedIn: $isLoggedIn
            )
        }
       .fullScreenCover(isPresented: $controller.showSignInView) {
           SignInView(
               showSignInView: $controller.showSignInView,
               isLoggedIn: $isLoggedIn
           )
        }
    }
}
