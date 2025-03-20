//
//  CartView.swift
//  LastBite
//
//  Created by Andrés Romero on 20/03/25.
//

import SwiftUI

// Modelo para cada ítem del carrito
struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let weight: String
    var quantity: Int
    let price: Double
    let imageName: String
}

// Vista principal del carrito
struct CartView: View {
    @State private var cartItems: [CartItem] = [
        CartItem(name: "Bell Pepper Red", weight: "1kg", quantity: 1, price: 4.99, imageName: "red_pepper"),
        CartItem(name: "Egg Chicken Red", weight: "4pcs", quantity: 1, price: 1.99, imageName: "chicken_eggs"),
        CartItem(name: "Organic Bananas", weight: "12kg", quantity: 1, price: 3.00, imageName: "bananas"),
        CartItem(name: "Ginger", weight: "250gm", quantity: 1, price: 2.99, imageName: "ginger")
    ]
    @State private var showCheckout = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Encabezado
                HStack {
                    Text("My Cart")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Lista de productos
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(cartItems.indices, id: \.self) { index in
                            CartRowView(
                                item: $cartItems[index],
                                removeAction: {
                                    cartItems.remove(at: index)
                                }
                            )
                        }
                    }
                }
                
                // Botón de Checkout
                Button(action: {
                        showCheckout = true
                    }) {
                        Text("Go to Checkout")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .padding()
                    .sheet(isPresented: $showCheckout) {
                        NavigationStack {
                            CheckoutView(cartItems: cartItems)
                                .presentationDetents([.medium, .large]) // Opcional, iOS 16+
                        }
                    }
            }
            .navigationBarHidden(true)  // Oculta la barra de navegación si quieres
        }
    }
}

// Vista individual para cada producto del carrito
struct CartRowView: View {
    @Binding var item: CartItem
    var removeAction: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Imagen del producto
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .padding(.leading)
            
            // Nombre y descripción
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(item.weight), Price")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Controles de cantidad
            HStack(spacing: 8) {
                Button(action: {
                    if item.quantity > 1 {
                        item.quantity -= 1
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                Text("\(item.quantity)")
                    .frame(width: 24)
                
                Button(action: {
                    item.quantity += 1
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            // Precio
            Text(String(format: "$%.2f", item.price))
                .frame(width: 60, alignment: .trailing)
            
            // Botón para eliminar
            Button(action: removeAction) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
            .padding(.trailing)
        }
        .padding(.vertical, 8)
    }
}

// Vista de previsualización
struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
