import SwiftUI

struct PhoneNumberView: View {
    @State private var phoneNumber: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            // ✅ Title
            Text("Enter your mobile number")
                .font(.title)
                .bold()
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // ✅ Phone Input Field (Fixes Applied)
            VStack(alignment: .leading, spacing: 5) {
                Text("Mobile Number")
                    .font(.footnote)
                    .foregroundColor(.gray)

                HStack {
                    
                    Image("colombia_flag")
                        .resizable()
                        .renderingMode(.original) // ✅ Prevents rendering issues
                        .scaledToFit()
                        .frame(width: 24, height: 16) // ✅ Ensures valid size
                    Text("+57")
                        .font(.headline)

                    TextField("Enter your number", text: $phoneNumber) // ✅ Placeholder Fix
                        .keyboardType(.numberPad)
                        .frame(height: 40)
                        .padding(.leading, 5)
                        .background(Color.clear)
                }
                .frame(height: 50)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer()

            // ✅ Next Button
            Button(action: {
                // Next step action
            }) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(false) // ✅ Keeps default back button
        .navigationTitle("Phone Number") // ✅ Adds a title
        .onDisappear {
            phoneNumber = "" // ✅ Clears state on exit
        }
    }
}

struct PhoneNumberView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { // ✅ Ensures proper navigation preview
            PhoneNumberView()
        }
    }
}

