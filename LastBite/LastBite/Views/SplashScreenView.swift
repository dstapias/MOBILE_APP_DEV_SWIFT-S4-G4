import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.primaryGreen // Using the custom color
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(systemName: "cart.fill") // Placeholder for your logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Text("LastBite")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("cheap food")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
