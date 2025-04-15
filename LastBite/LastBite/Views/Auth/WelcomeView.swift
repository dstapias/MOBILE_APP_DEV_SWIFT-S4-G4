import SwiftUI

struct WelcomeView: View {
    @StateObject private var controller = WelcomeController()
    @Binding var isLoggedIn: Bool

    var body: some View {
        GeometryReader { geometry in // GeometryReader calcula el tamaño disponible
            ZStack { // ZStack para apilar imagen y contenido
                // Fondo
                Image("WelcomeImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    // Hacemos que la imagen intente llenar el espacio dado por GeometryReader
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // Nota: Ya no es estrictamente necesario .edgesIgnoringSafeArea aquí en la imagen
                    // si el contenedor superior (GeometryReader) lo ignora.

                // Contenido Principal (VStack con textos y botones)
                VStack {
                   // ... (Spacer, Text, Button, HStack - Sin cambios) ...
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
                            .background(Color.primaryGreen).cornerRadius(10) // Asume que Color.primaryGreen existe
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
                     // Usa el inset inferior del GeometryReader para el padding
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))

                } // Fin VStack Contenido
                // Puedes mantener o quitar este frame y padding del VStack según el diseño deseado
                // .frame(width: geometry.size.width * 0.9)
                .padding()

            } // Fin ZStack
            // No es necesario aplicar frame al ZStack si GeometryReader lo contiene

        } // Fin GeometryReader
        .ignoresSafeArea() // <--- ¡APLICA EL MODIFICADOR AQUÍ! (O .edgesIgnoringSafeArea(.all))

        // Los fullScreenCover se aplican después de ignoresSafeArea
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
    } // Fin body
} // Fin struct WelcomeView

// --- Preview y Controller (sin cambios) ---
// struct WelcomeView_Previews: PreviewProvider { ... }
// class WelcomeController: ObservableObject { ... }
