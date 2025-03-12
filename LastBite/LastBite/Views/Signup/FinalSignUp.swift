import SwiftUI

struct FinalSignUpView: View {
    @Binding var showFinalSignUpView: Bool // ✅ Controls visibility
    @ObservedObject var userService = SignupUserService.shared // ✅ Shared user service
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage: Bool = false
    @State private var navigateToSignIn = false // ✅ Controls navigation manually

    // ✅ Computed property for button validation
    private var isSubmitDisabled: Bool {
        return userService.name.trimmingCharacters(in: .whitespaces).isEmpty ||
               !isValidEmail(userService.email) ||
               userService.password.count < 6
    }

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
                
                // ✅ Name Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Full Name")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    TextField("Enter your name", text: $userService.name)
                        .autocapitalization(.words)
                        .padding(.bottom, 5)
                        .onChange(of: userService.name) { _ in validateFields() }
                    
                    Divider()
                }

                // ✅ Email Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    TextField("Enter your email", text: $userService.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 5)
                        .onChange(of: userService.email) { _ in validateFields() }

                    Divider()
                }

                if !isValidEmail(userService.email) && !userService.email.isEmpty {
                    Text("Invalid email format")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                // ✅ Password Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Password")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $userService.password)
                        } else {
                            SecureField("Enter your password", text: $userService.password)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 5)
                    .onChange(of: userService.password) { _ in validateFields() }

                    Divider()
                }

                if userService.password.count < 6 && !userService.password.isEmpty {
                    Text("Password must be at least 6 characters")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                // ✅ Terms & Privacy
                Text("By continuing you agree to our **Terms of Service** and **Privacy Policy**.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                // ✅ Submit Button
                Button(action: { FinalSignUpUser() }) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50) // ✅ Ensures the whole button is tappable
                    .background(isSubmitDisabled || isLoading ? Color.gray : Color.green) // ✅ Disable logic
                    .cornerRadius(10)
                    .opacity(isSubmitDisabled ? 0.5 : 1) // ✅ Reduce opacity when disabled
                }
                .padding(.top, 10)
                .disabled(isSubmitDisabled || isLoading) // ✅ Prevent multiple taps while loading
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
        .onAppear {
            userService.userType = Constants.USER_TYPE_CUSTOMER // ✅ Ensure userType is set when view appears
        }
    }
    
    // ✅ Signup Function Using `SignupUserService`
    func FinalSignUpUser() {
        isLoading = true
        errorMessage = nil
        
        userService.registerUser { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    print("✅ User created successfully!")
                    showSuccessMessage = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // ✅ Email Validation Function
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    // ✅ Field Validation Function
    func validateFields() {
        // This triggers `isSubmitDisabled` to recompute
        _ = isSubmitDisabled
    }
}

// ✅ Preview
struct FinalSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        FinalSignUpView(showFinalSignUpView: .constant(true))
    }
}
