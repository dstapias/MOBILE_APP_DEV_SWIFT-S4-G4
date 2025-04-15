import SwiftUI

struct SignupView: View {
    // Bindings para control parental (sin cambios)
    @Binding var showSignupView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. StateObject para el nuevo Controller
    @StateObject private var controller = SignupController()

    // 2. El estado local para navegación se elimina
    // @State private var showPhoneNumberView = false // ELIMINADO

    // El inicializador por defecto está bien si SignupController no necesita parámetros.

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Botón Volver (sin cambios)
                HStack {
                    Button(action: { showSignupView = false }) {
                        Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                    }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: geometry.size.height * 0.05)

                // Imagen y Textos (sin cambios)
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
                    // Estilo del botón (sin cambios)
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

                // Texto "Or connect..." (sin cambios)
                Text("Or connect with social media")
                    .font(.footnote).foregroundColor(.gray)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Botones Sociales
                VStack(spacing: 15) {
                    // 4. Llama a las acciones correspondientes del controller
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
            } // Fin VStack Principal
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding() // Considera si este padding general es necesario o causa doble padding
            // 5. fullScreenCover usa la propiedad publicada del controller
            .fullScreenCover(isPresented: $controller.showPhoneNumberView) {
                 // Pasa los bindings necesarios a la siguiente vista
                 // Nota: PhoneNumberView ya debería estar refactorizada
                 PhoneNumberView(showPhoneNumberView: $controller.showPhoneNumberView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        } // Fin GeometryReader
    } // Fin body

    // Componente botón social ahora acepta una acción
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
} // Fin struct SignupView

// --- Preview ---
struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(
            showSignupView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
        // No necesita EnvironmentObject por ahora, ya que el controller no usa servicios compartidos (aún)
    }
}
