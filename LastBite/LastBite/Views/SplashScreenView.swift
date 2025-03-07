import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.primaryGreen
                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 10) {
                Image("pizza_loading")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 0.1) {
                    Text("LastBite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("cheap food")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
