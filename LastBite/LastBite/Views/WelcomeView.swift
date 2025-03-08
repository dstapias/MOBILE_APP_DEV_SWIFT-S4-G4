import SwiftUI

struct WelcomeView: View {
    @State private var showSignupView = false
    @State private var showSignInView = false
    var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Image("WelcomeImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: max(geometry.size.width, 1), height: max(geometry.size.height, 1))
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer(minLength: geometry.size.height * 0.1)
                        Text("Welcome to our store")
                            .font(.system(size: min(geometry.size.width * 0.08, 36))) // ✅ Scales for iPhone/iPad
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        Text("Get your food cheaper than anywhere")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 5)
                            .padding(.horizontal, 30)
                            .background(Color.black.opacity(0.5))
                        Spacer()
                        Button(action: {
                            showSignupView = true
                        }) {
                            Text("Go to Signup")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: min(geometry.size.width * 0.7, 300))
                                .background(Color.primaryGreen)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
                        HStack {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Button(action: {
                                showSignInView = true
                            }) {
                                Text("Sign-in")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .bold()
                            }
                        }
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                    }
                    .frame(width: geometry.size.width * 0.9)
                    .padding()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .ignoresSafeArea()
            .fullScreenCover(isPresented: $showSignupView) {
                SignupView(showSignupView: $showSignupView, showSignInView: $showSignInView)
                   }
            .fullScreenCover(isPresented: $showSignInView) {
                       SignInView(showSignInView: $showSignInView)
                   }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
                .previewDevice("iPhone")

            WelcomeView()
                .previewDevice("iPad")
        }
    }
}

