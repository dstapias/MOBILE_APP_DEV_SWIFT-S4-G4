import SwiftUI

struct FourDigitCodeView: View {
    @Binding var showFourDigitCodeView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @ObservedObject var userService = SignupUserService.shared // ✅ Shared user service
    @FocusState private var isCodeFocused: Bool // ✅ Controls keyboard focus
    @State private var showLocationView = false
    @Binding var isLoggedIn: Bool
    @State private var isLoading = false
    @State private var errorMessage: String = ""


    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // ✅ Back Button (Top-Left)
                HStack {
                    Button(action: {
                        showFourDigitCodeView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // ✅ Title
                Text("Enter your 6-digit code")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ✅ 6-Digit Code Input (Hidden with `*`)
                VStack {
                    HStack(spacing: 15) {
                        ForEach(0..<6, id: \.self) { index in
                            Text(userService.verificationCode.count > index ? "•" : "_") // ✅ Uses `SignupUserService`
                                .font(.largeTitle)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    // ✅ Hidden `TextField` for Input
                    TextField("", text: $userService.verificationCode) // ✅ Uses shared service
                        .keyboardType(.numberPad)
                        .focused($isCodeFocused)
                        .textContentType(.oneTimeCode)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onChange(of: userService.verificationCode) { newValue in
                            // ✅ Ensures only 6 digits
                            if newValue.count > 6 {
                                userService.verificationCode = String(newValue.prefix(6))
                            }
                        }
                        .onAppear {
                            isCodeFocused = true // ✅ Opens keyboard automatically
                        }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // ✅ Next Button
                Button(action: {
                    if userService.verificationCode.count == 6 {
                        isLoading = true
                        SignupUserService.shared.verifyCode { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                switch result {
                                case .success:
                                    // On successful verification, update the login state and navigate forward
                                    showLocationView = true
                                    print("User authenticated successfully!")
                                case .failure(let error):
                                    errorMessage = "Error: \(error.localizedDescription)"
                                    print(errorMessage)
                                }
                            }
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding()
                            .background(userService.verificationCode.count == 6 ? Color.green : Color.gray)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(userService.verificationCode.count < 6 || isLoading) // Prevents navigation if incomplete or loading
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("6 Digit Code")
        }
        .fullScreenCover(isPresented: $showLocationView) {
            LocationView(showLocationView: $showLocationView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
        }
    }
}
