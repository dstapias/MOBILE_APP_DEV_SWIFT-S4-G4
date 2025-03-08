import SwiftUI
import FirebaseAuth

struct FinalSignUpView: View {
    @Binding var showFinalSignUpView: Bool // ✅ Control visibility
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage: Bool = false
    @State private var navigateToSignIn = false // ✅ Controls navigation manually

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 15) {
                
                // ✅ Back Button
                HStack {
                    Button(action: { showFinalSignUpView = false }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }
                
                Spacer()

                // ✅ Title
                Text("Sign-up")
                    .font(.title)
                    .bold()
                
                Text("Enter your credentials to continue")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                // ✅ Email Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 5)
                    
                    Divider()
                }

                // ✅ Password Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                }

                // ✅ Terms & Privacy
                Text("By continuing you agree to our **Terms of Service** and **Privacy Policy**.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                // ✅ Submit Button
                Button(action: { FinalSignUpUser() }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 10)
                .disabled(isLoading)
                .alert(isPresented: $showSuccessMessage) { // ✅ Success Alert
                    Alert(
                        title: Text("Success"),
                        message: Text("User created successfully!"),
                        dismissButton: .default(Text("OK")) {
                            navigateToSignIn = true // ✅ Correct navigation handling
                        }
                    )
                }

                // ✅ Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                
                Spacer()

                // ✅ Sign-in Redirect
                HStack {
                    Text("Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        navigateToSignIn = true // ✅ Navigate to Sign-in
                    }) {
                        Text("Sign-in")
                            .font(.footnote)
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: geometry.size.width * 0.9)
        }
        .fullScreenCover(isPresented: $navigateToSignIn) { // ✅ Opens Sign-in properly
            SignInView(showSignInView: $navigateToSignIn) // ✅ No binding required
        }
    }
    
    // ✅ Firebase Signup Function
    func FinalSignUpUser() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    print("✅ User created successfully!")
                    showSuccessMessage = true // ✅ Show success alert
                }
            }
        }
    }
}

// ✅ Preview
struct FinalSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        FinalSignUpView(showFinalSignUpView: .constant(true))
    }
}
