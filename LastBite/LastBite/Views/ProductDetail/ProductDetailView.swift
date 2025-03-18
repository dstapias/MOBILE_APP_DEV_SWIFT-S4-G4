//
//  ProductDetailView.swift
//  LastBite
//
//  Created by Andrés Romero on 17/03/25.
//

import SwiftUI

struct ProductDetailView: View {
    // Ejemplo de estado para controlar la cantidad
    @State private var quantity: Int = 1
    
    // Datos de ejemplo para ilustrar la vista
    let productName: String = "Naturel Red Apple"
    let productPrice: Double = 4.99
    let productWeight: String = "1kg"
    let productDescription: String = """
Apples are nutritious. Apples may be good for weight loss.
Apples may be good for your heart, as part of a healthful
and varied diet.
"""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Imagen del producto
                Image("red_apple")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
                
                // Título y breve información (peso y precio)
                VStack(alignment: .leading, spacing: 4) {
                    Text(productName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(productWeight)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", productPrice))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                
                // Sección para seleccionar cantidad
                HStack(spacing: 16) {
                    // Puedes usar un Stepper para controlar la cantidad
                    Stepper(value: $quantity, in: 1...10) {
                        Text("Quantity: \(quantity)")
                            .font(.subheadline)
                    }
                    .labelsHidden()
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Product Detail
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Detail")
                        .font(.headline)
                    
                    Text(productDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    // Ejemplo de "chips" o etiquetas
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TagView(text: "100g")
                            TagView(text: "Fresh")
                            TagView(text: "Organic")
                        }
                    }
                }
                .padding(.horizontal)
                
                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reviews")
                        .font(.headline)
                    
                    // Estrellas de ejemplo
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        // Podrías mostrar un texto con la calificación
                        Text("5/5")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Botón "Add To Basket"
                Button(action: {
                    // Acción al presionar el botón
                }) {
                    Text("Add To Basket")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .navigationTitle("Product Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(12)
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProductDetailView()
        }
    }
}
