import SwiftUI

struct SignInView: View {
    @Binding var showSignInView: Bool // ✅ Binding to allow closing Sign-in
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // ✅ Custom Back Button
                HStack {
                    Button(action: {
                        showSignInView = false // ✅ Closes Sign-in view
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
                        Button(action: {}) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }

                    // ✅ Login Button
                    Button(action: {}) {
                        Text("Log-in")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: geometry.size.width * 0.9)

                Spacer() // ✅ Centers content vertically
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// ✅ Preview with Correct Binding
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true)) // ✅ Fix for preview
    }
}
