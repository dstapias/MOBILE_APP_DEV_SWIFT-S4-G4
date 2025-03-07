import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image("WelcomeImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        Spacer(minLength: geometry.size.height * 0.1) // Adjusts dynamically

                        // Title
                        Text("Welcome to our store")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .background(Color.black.opacity(0.5)) // Adds slight contrast
                            .cornerRadius(10)

                        // Subtitle
                        Text("Get your food cheaper than anywhere")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 5)
                            .padding(.horizontal, 30)
                            .background(Color.black.opacity(0.5)) // Adds slight contrast

                        Spacer()

                        NavigationLink(destination: SignupView()) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: geometry.size.width * 0.7) // Adjusts width for all devices
                                .background(Color.primaryGreen)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20) // Space before the sign-in link

                        // Sign-in Option
                        HStack {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Text("Sign-in")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .bold()
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20) // Prevents overlap with home indicator
                    }
                    .frame(width: geometry.size.width * 0.9) // Keeps text width consistent
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
                .previewDevice("iPhone 14 Pro")
            
            WelcomeView()
                .previewDevice("iPad Air (5th generation)")
        }
    }
}
