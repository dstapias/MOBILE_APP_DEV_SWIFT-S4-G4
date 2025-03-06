import SwiftUI

struct SignupView: View {
    var body: some View {
        VStack {
            // Top Image
            Image("bag_of_fruits") // Ensure this image is in Assets.xcassets
                .resizable()
                .scaledToFit()
                .frame(width: 219, height: 384)
                .padding(.top, 40)

            // Text Stack (Left-Aligned)
            VStack(alignment: .leading, spacing: 5) { // Added better spacing
                Text("Get cheap food")
                    .font(.system(size: 26, weight: .regular)) // Regular, not bold
                
                Text("with LastBite")
                    .font(.system(size: 26, weight: .regular)) // Regular, not bold
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensures full-width alignment
            .padding(.horizontal, 40) // Adjusts left/right padding
            .padding(.top, 10)

            // Country Code Section (Proper Spacing)
            HStack(spacing: 10) { // Increased spacing from 3 to 10
                Image("colombia_flag")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 14)
                Text("+57") // Default country code
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Forces left alignment
            .padding(.horizontal, 40)
            .padding(.top, 10) // Added padding to separate from text above

            Divider()
                .padding(.horizontal, 40)

            // Social Media Connection Info
            Text("Or connect with social media") // Shortened text for better UI
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .center)

            // Social Media Buttons
            VStack(spacing: 15) {
                Button(action: {
                    // Google Signup Action
                }) {
                    HStack {
                        Image("google_login")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        
                        Spacer().frame(width: 12) // ✅ Ensures even spacing

                        Text("Continue with Google")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading) // ✅ Align text
                    }
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: {
                    // Facebook Signup Action
                }) {
                    HStack {
                        Image("facebook_login")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        
                        Spacer().frame(width: 12)

                        Text("Continue with Facebook")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(.horizontal, 20)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
