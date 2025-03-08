import SwiftUI

struct FourDigitCodeView: View {
    @Binding var showFourDigitCodeView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @State private var code: String = "" // ✅ Holds the 4-digit input
    @FocusState private var isCodeFocused: Bool // ✅ Controls keyboard focus
    @State private var showLocationView = false 
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // ✅ Properly Positioned Back Button (Top-Left)
                HStack {
                    Button(action: {
                        showFourDigitCodeView = false
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
                Text("Enter your 4-digit code")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ✅ 4-Digit Code Input (Hidden with `*`)
                VStack {
                    HStack(spacing: 15) {
                        ForEach(0..<4, id: \.self) { index in
                            Text(code.count > index ? "•" : "_") // ✅ Shows `•` for filled spots, `_` for empty
                                .font(.largeTitle)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    // ✅ Hidden `TextField` for Input
                    TextField("", text: $code)
                        .keyboardType(.numberPad)
                        .focused($isCodeFocused) // ✅ Focus on appear
                        .textContentType(.oneTimeCode) // ✅ Helps autofill from SMS
                        .frame(width: 1, height: 1) // ✅ Hides the actual field
                        .opacity(0.01) // ✅ Makes it invisible
                        .onChange(of: code) { newValue in
                            // ✅ Ensures only 4 digits
                            if newValue.count > 4 {
                                code = String(newValue.prefix(4))
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
                    if (code.count == 4){
                        showLocationView = true
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(code.count == 4 ? Color.green : Color.gray)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(false) // ✅ Default back button is kept
            .navigationTitle("4 Digit Code") // ✅ Adds a title
        }
        .fullScreenCover(isPresented: $showLocationView) {
            LocationView(showLocationView: $showLocationView, showSignInView: $showSignInView)
        }
    }
}
