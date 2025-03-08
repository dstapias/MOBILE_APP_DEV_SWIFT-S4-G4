import SwiftUI

struct PhoneNumberView: View {
    @Binding var showPhoneNumberView: Bool // ✅ Controls manual navigation
    @State private var phoneNumber: String = ""
    @FocusState private var isPhoneNumberFocused: Bool // ✅ Controls keyboard focus
    @State private var showFourDigitCodeView = false // ✅ Controls PhoneNumberView navigation
    
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

                        TextField("", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .frame(height: 40)
                            .padding(.leading, 5)
                            .background(Color.clear)
                            .focused($isPhoneNumberFocused) // ✅ Focus on appear
                            .onChange(of: phoneNumber) { newValue in
                                // ✅ Remove non-numeric characters
                                let filtered = newValue.filter { $0.isNumber }

                                // ✅ Limit to 10 digits
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
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
                    if phoneNumber.count == 10 {
                        showFourDigitCodeView = true
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(phoneNumber.count == 10 ? Color.green : Color.gray) // ✅ Enables only when input is valid
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(phoneNumber.count < 10) // ✅ Prevents navigation if input is incomplete
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("Phone Number")
            .onAppear {
                isPhoneNumberFocused = true
            }
        }
        .fullScreenCover(isPresented: $showFourDigitCodeView) {
            FourDigitCodeView(showFourDigitCodeView: $showFourDigitCodeView)
        }
    }
}
