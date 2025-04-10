import SwiftUI

struct SignupView: View {
    @Binding var showSignupView: Bool // ✅ Binding to go back to WelcomeView
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @State private var showPhoneNumberView = false // ✅ Controls PhoneNumberView navigation
    @Binding var isLoggedIn: Bool

    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // ✅ Back Button Positioned in the Top Left Corner
                HStack {
                    Button(action: {
                        showSignupView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20) // ✅ Adds space from the left
                    .padding(.top, geometry.safeAreaInsets.top + 10) // ✅ Prevents overlap with the notch
                    
                    Spacer() // ✅ Pushes button to the left
                }
                .frame(maxWidth: .infinity) // ✅ Ensures full width

                Spacer(minLength: geometry.size.height * 0.05) // Dynamic spacing

                Image("bag_of_fruits")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(219, geometry.size.width * 0.5), height: min(384, geometry.size.height * 0.35)) // Adjust size dynamically
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Get cheap food")
                        .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular)) // Adjust size for iPad
                    Text("with LastBite")
                        .font(.system(size: geometry.size.width > 600 ? 32 : 26, weight: .regular))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 10)

                Button(action: {
                    showPhoneNumberView = true
                }) {
                    HStack {
                        Image("colombia_flag")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 14)
                        Text("+57")
                            .font(.headline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.horizontal, 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 10)

                Divider()
                    .padding(.horizontal, 40)

                // ✅ Social Media Connection Info
                Text("Or connect with social media")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)

                // ✅ Social Media Buttons
                VStack(spacing: 15) {
                    socialButton(image: "google_login", text: "Continue with Google", color: Color.blue)
                    socialButton(image: "facebook_login", text: "Continue with Facebook", color: Color.blue.opacity(0.8))
                }
                .frame(maxWidth: min(500, geometry.size.width * 0.8))
                .padding(.top, 20)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding()
            .fullScreenCover(isPresented: $showPhoneNumberView) {
                PhoneNumberView(showPhoneNumberView: $showPhoneNumberView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
            }
        }
    }

    // ✅ Reusable Social Button Component
    private func socialButton(image: String, text: String, color: Color) -> some View {
        Button(action: {}) {
            HStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)

                Spacer().frame(width: 12)

                Text(text)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(.horizontal, 20)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(
            showSignupView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
    }
}
