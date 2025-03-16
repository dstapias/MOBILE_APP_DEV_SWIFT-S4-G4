import SwiftUI

struct ContentView: View {
    @State private var isActive = false
    @Binding var isLoggedIn: Bool


    var body: some View {
        ZStack {
            if isActive {
                WelcomeView(isLoggedIn: $isLoggedIn)
            } else {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isLoggedIn: .constant(false))
    }
}

