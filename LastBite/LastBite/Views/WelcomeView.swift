import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Image("WelcomeImage") // Ensure this image is in Assets.xcassets
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -30)
                
                VStack {
                    Spacer()
                    
                    Text("Welcome to our store")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: 180)
                    
                    Text("Get your food cheaper than anywhere")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .offset(y: 180)
                    
                    Spacer()
                    
                    NavigationLink(destination: SignupView()) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.primaryGreen)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)

                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("Sign-in")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                .padding()
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
