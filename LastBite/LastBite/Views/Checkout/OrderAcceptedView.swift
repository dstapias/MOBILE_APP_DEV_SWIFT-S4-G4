//
//  OrderAcceptedView.swift
//  LastBite
//
//  Created by Andrés Romero on 20/03/25.
//

import SwiftUI

struct OrderAcceptedView: View {
    @State private var navigateToHome = false
    @AppStorage("isLoggedIn") private var isLoggedIn = true

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("Check")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.bottom, 24)
                
                // Texto principal
                Text("Your Order has been accepted")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Botón para volver al Home
                Button(action: {
                    navigateToHome = true
                }) {
                    Text("Back to Home")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            // Se activa la navegación programática cuando navigateToHome es true
            .navigationDestination(isPresented: $navigateToHome) {
                MainTabView().navigationBarBackButtonHidden(true)
            }
        }
    }
}

struct OrderAcceptedView_Previews: PreviewProvider {
    static var previews: some View {
        OrderAcceptedView()
    }
}
