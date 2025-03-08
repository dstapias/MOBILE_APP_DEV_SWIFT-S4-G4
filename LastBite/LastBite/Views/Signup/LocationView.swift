//
//  LocationView.swift
//  LastBite
//
//  Created by David Santiago on 7/03/25.
//

import SwiftUI

struct LocationView: View {
    @Binding var showLocationView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @State private var selectedZone: String = "Bogotá" // ✅ Default zone
    @State private var selectedArea: String = "" // ✅ Stores selected area
    @State private var showFinalSignUpView = false // ✅ Controls navigation to the next screen


    let zones = ["Bogotá", "Medellín", "Santa Marta", "Cali"] // Example zones
    let areas = ["Residential", "Commercial", "Industrial", "Other"] // Example area types

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // ✅ Back Button (Top-left)
                HStack {
                    Button(action: {
                        showLocationView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()
                }

                // ✅ Location Icon
                Image("location_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 20)

                // ✅ Title & Subtitle
                Text("Select Your Location")
                    .font(.title2)
                    .bold()
                    .padding(.top, 10)

                Text("Switch on your location to stay in tune with what’s happening in your area")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 5)

                // ✅ Zone Picker
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Zone")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Menu {
                        ForEach(zones, id: \.self) { zone in
                            Button(action: { selectedZone = zone }) {
                                Text(zone)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedZone)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)

                // ✅ Area Picker
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Area")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Menu {
                        ForEach(areas, id: \.self) { area in
                            Button(action: { selectedArea = area }) {
                                Text(area)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedArea.isEmpty ? "Types of your area" : selectedArea)
                                .font(.headline)
                                .foregroundColor(selectedArea.isEmpty ? .gray : .black)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                Spacer()

                // ✅ Next Button
                Button(action: {
                    showFinalSignUpView = true
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)

            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Location")
        }
        .fullScreenCover(isPresented: $showFinalSignUpView) {
            FinalSignUpView(showFinalSignUpView: $showFinalSignUpView)
        }
    }
}
