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
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int


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
                    selectedTab = 0
                    // Call the dismiss action
                    dismiss()
                    // Optionally call the callback if provided
                    // onDismiss?()
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
        }
    }
}
