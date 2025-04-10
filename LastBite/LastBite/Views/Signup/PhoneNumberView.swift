import SwiftUI

struct PhoneNumberView: View {
    @Binding var showPhoneNumberView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @ObservedObject var userService = SignupUserService.shared // ✅ Shared user service
    @FocusState private var isPhoneNumberFocused: Bool // ✅ Controls keyboard focus
    @State private var showFourDigitCodeView = false // ✅ Controls PhoneNumberView navigation
    @Binding var isLoggedIn: Bool

    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // ✅ Properly Positioned Back Button (Top-Left)
                HStack {
                    Button(action: {
                        showPhoneNumberView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20) // ✅ Moves it away from the left edge
                    .padding(.top, geometry.safeAreaInsets.top + 10) // ✅ Prevents it from going too high

                    Spacer() // ✅ Pushes it to the left
                }
                .frame(maxWidth: .infinity) // ✅ Ensures full-width

                // ✅ Title
                Text("Enter your mobile number")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ✅ Phone Input Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    HStack {
                        Image("colombia_flag")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 14)

                        Text("+57")
                            .font(.headline)

                        TextField("", text: $userService.phoneNumber) // ✅ Uses shared service
                            .keyboardType(.numberPad)
                            .frame(height: 40)
                            .padding(.leading, 5)
                            .background(Color.clear)
                            .focused($isPhoneNumberFocused) // ✅ Focus on appear
                            .onChange(of: userService.phoneNumber) { newValue in
                                // ✅ Remove non-numeric characters
                                let filtered = newValue.filter { $0.isNumber }

                                // ✅ Limit to 10 digits
                                if filtered.count > 10 {
                                    userService.phoneNumber = String(filtered.prefix(10))
                                } else {
                                    userService.phoneNumber = filtered
                                }
                            }
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // ✅ Next Button (Only Enables When 10 Digits Are Entered)
                Button(action: {
                    if userService.phoneNumber.count == 10 || (userService.phoneNumber.count > 10 && !userService.phoneNumber.hasPrefix("+")) {
                        // Only add the country code if it's not already there
                        if !userService.phoneNumber.hasPrefix("+") {
                            let fullPhoneNumber = "+57" + userService.phoneNumber
                            userService.phoneNumber = fullPhoneNumber
                        }
                        
                        SignupUserService.shared.sendVerificationCode { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    print("Verification code sent successfully.")
                                    showFourDigitCodeView = true
                                case .failure(let error):
                                    print("Error sending verification code: \(error.localizedDescription)")
                                    // Optionally, show an alert or message to the user
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(userService.phoneNumber.count >= 10 ? Color.green : Color.gray)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("Phone Number")
            .onAppear {
                isPhoneNumberFocused = true
            }
        }
        .fullScreenCover(isPresented: $showFourDigitCodeView) {
            FourDigitCodeView(showFourDigitCodeView: $showFourDigitCodeView, showSignInView: $showSignInView, isLoggedIn: $isLoggedIn)
        }
    }
}
