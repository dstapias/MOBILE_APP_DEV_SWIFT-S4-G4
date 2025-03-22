import SwiftUI

struct SignInView: View {
    @Binding var showSignInView: Bool
    @ObservedObject var authService = SignInUserService.shared // ✅ Uses shared SignInUserService
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @Binding var isLoggedIn: Bool


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

                        TextField("Enter your email", text: Binding(
                            get: { authService.email ?? "" },
                            set: { authService.email = $0 }
                        ))
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
                                TextField("Enter your password", text: Binding(
                                    get: { authService.password ?? "" },
                                    set: { authService.password = $0 }
                                ))
                            } else {
                                SecureField("Enter your password", text: Binding(
                                    get: { authService.password ?? "" },
                                    set: { authService.password = $0 }
                                ))
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
                        Button(action: resetPassword) {
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
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
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

    // ✅ Call AuthService for Sign-in
    private func signInUser() {
        isLoading = true
        authService.signInUser { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    showSignInView = false
                    isLoggedIn = true
                case .failure(let error):
                    authService.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // ✅ Call AuthService for Password Reset
    private func resetPassword() {
        authService.resetPassword { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    authService.errorMessage = message
                case .failure(let error):
                    authService.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// ✅ Preview with Correct Binding
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true), isLoggedIn: .constant(false))
    }
}
