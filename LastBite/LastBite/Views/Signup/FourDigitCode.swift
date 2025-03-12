import SwiftUI

struct FourDigitCodeView: View {
    @Binding var showFourDigitCodeView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @ObservedObject var userService = SignupUserService.shared // ✅ Shared user service
    @FocusState private var isCodeFocused: Bool // ✅ Controls keyboard focus
    @State private var showLocationView = false

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
                Text("Enter your 4-digit code")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ✅ 4-Digit Code Input (Hidden with `*`)
                VStack {
                    HStack(spacing: 15) {
                        ForEach(0..<4, id: \.self) { index in
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
                            // ✅ Ensures only 4 digits
                            if newValue.count > 4 {
                                userService.verificationCode = String(newValue.prefix(4))
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
                    if userService.verificationCode.count == 4 {
                        showLocationView = true
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(userService.verificationCode.count == 4 ? Color.green : Color.gray)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(userService.verificationCode.count < 4) // ✅ Prevents navigation if incomplete
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("4 Digit Code")
        }
        .fullScreenCover(isPresented: $showLocationView) {
            LocationView(showLocationView: $showLocationView, showSignInView: $showSignInView)
        }
    }
}
