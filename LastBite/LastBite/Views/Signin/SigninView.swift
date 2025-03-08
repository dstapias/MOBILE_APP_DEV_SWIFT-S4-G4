import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @Binding var showSignInView: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String = "" // ✅ Stores Firebase error messages
    @State private var isLoading: Bool = false  // ✅ Shows a loading indicator

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // ✅ Custom Back Button
                HStack {
                    Button(action: {
                        showSignInView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()
                }

                Spacer() // ✅ Centers content vertically

                VStack(alignment: .leading, spacing: 10) {
                    // ✅ Title
                    Text("Sign-in")
                        .font(.title)
                        .bold()

                    Text("Enter your email and password")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    // ✅ Email Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        TextField("Enter your email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
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

                    // ✅ Forgot Password
                    HStack {
                        Spacer()
                        Button(action: {
                            resetPassword()
                        }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }

                    // ✅ Firebase Login Button
                    Button(action: signInUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                        } else {
                            Text("Log-in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    // ✅ Show Firebase Error Messages
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: geometry.size.width * 0.9)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // ✅ Firebase Authentication: Sign-in Function
    private func signInUser() {
        isLoading = true
        errorMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    showSignInView = false // ✅ Close the sign-in screen
                }
            }
        }
    }

    // ✅ Firebase Authentication: Password Reset
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to reset the password."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    errorMessage = "Password reset link sent to your email."
                }
            }
        }
    }
}

// ✅ Preview with Correct Binding
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true))
    }
}
