import SwiftUI

struct ContentView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive {
                WelcomeView()
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
        ContentView()
    }
}

