//
//  OrderStatusView.swift
//  LastBite
//
//  Created by Andrés Romero on 21/03/25.
//

import SwiftUI

struct OrderStatusView: View {
    let statusMessage: String
    let buttonTitle: String
    let imageName: String
    let onButtonTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50) 
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusMessage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Button(action: onButtonTap) {
                    Text(buttonTitle)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
