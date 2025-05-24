//
//  UpdateStoreView.swift
//  LastBite
//
//  Created by Andrés Romero on 13/05/25.
//

import SwiftUI
import PhotosUI

struct UpdateStoreView: View {
    let store: Store
    @ObservedObject var controller: StoreController
    @ObservedObject var homeController: HomeController
    @ObservedObject var networkMonitor: NetworkMonitor
    var onDismissAfterUpdate: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var nit: String = ""
    @State private var address: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var opensAtDate: Date = Date()
    @State private var closesAtDate: Date = Date()
    @State private var successMessage: String?
    @State private var errorMessage: String?

    // Image handling
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var newBase64Image: String? = nil   // Base64 of the NEWLY selected image

    @State private var isCreating: Bool = false
    @State private var showCreatedAlert: Bool = false
    
    @State private var nameInput: String = ""
    @State private var nitInput: String = ""
    @State private var addressInput: String = ""
    @State private var latitudeInput: String = ""
    @State private var longitudeInput: String = ""
    @State private var opensAtInput: String = ""
    @State private var closesAtInput: String = ""
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // Asegúrate que coincida con el formato de tu backend
        formatter.locale = Locale(identifier: "en_US_POSIX") // Para consistencia en el parseo
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // O la zona horaria relevante si es necesario
        return formatter
    }()
    
    

    init(store: Store, controller: StoreController, homeController: HomeController, networkMonitor: NetworkMonitor, onDismissAfterUpdate: (() -> Void)? = nil) {
        self.store = store
        self.controller = controller
        self.homeController = homeController
        self.onDismissAfterUpdate = onDismissAfterUpdate
        self.networkMonitor = networkMonitor
        // Inicializar los @State con los valores de la tienda actual
                _nameInput = State(initialValue: store.name)
                _nitInput = State(initialValue: store.nit)
                _addressInput = State(initialValue: store.address)
                _latitudeInput = State(initialValue: String(store.latitude))
                _longitudeInput = State(initialValue: String(store.longitude))
                
                // Inicializar DatePickers (manejando posible fallo de parseo)
                if let opensDate = Self.timeFormatter.date(from: store.opens_at) {
                    _opensAtDate = State(initialValue: opensDate)
                } else {
                    _opensAtDate = State(initialValue: Date()) // Fallback
                    print("⚠️ Error al parsear opens_at: \(store.opens_at) para tienda \(store.store_id)")
                }
                if let closesDate = Self.timeFormatter.date(from: store.closes_at) {
                    _closesAtDate = State(initialValue: closesDate)
                } else {
                    _closesAtDate = State(initialValue: Date()) // Fallback
                    print("⚠️ Error al parsear closes_at: \(store.closes_at) para tienda \(store.store_id)")
                }
    }

    var body: some View {
        if (!networkMonitor.isConnected) {
                    Text("You are offline. Don't worry, you can continue editing or deleting all your changes will be saved and synchronized when internet is available.")
                .foregroundColor(.red)
                .padding(.horizontal)
                .transition(.opacity)
                
            
        }
        Form {
            Section(header: Text("Store Info")) {
                
                // Nombre (máx 50 caracteres)
                TextField("Name", text: $nameInput)
                    .onChange(of: nameInput) { newValue in
                        if newValue.count > 50 {
                            nameInput = String(newValue.prefix(50))
                        }
                    }

                // Detalle (máx 50 caracteres)
                TextField("NIT", text: $nitInput)
                    .onChange(of: nitInput) { newValue in
                        if newValue.count > 50 {
                            nitInput = String(newValue.prefix(50))
                        }
                    }
                TextField("Address", text: $addressInput)
                    .onChange(of: addressInput) { newValue in
                        if newValue.count > 50 {
                            addressInput = String(newValue.prefix(50))
                        }
                    }
                
                TextField("Latitude", text: $latitudeInput)
                    .onChange(of: latitudeInput) { newValue in
                        if newValue.count > 50 {
                            latitudeInput = String(newValue.prefix(50))
                        }
                    }
                
                TextField("Longitude", text: $longitudeInput)
                    .onChange(of: longitudeInput) { newValue in
                        if newValue.count > 50 {
                            longitudeInput = String(newValue.prefix(50))
                        }
                    }
                DatePicker("Opens At", selection: $opensAtDate, displayedComponents: .hourAndMinute)
                DatePicker("Closes At", selection: $closesAtDate, displayedComponents: .hourAndMinute)
            }

            Section(header: Text("Store Image")) {
                                if let newImage = selectedImage {
                                    Image(uiImage: newImage)
                                        .resizable().scaledToFit().frame(height: 150).cornerRadius(10)
                                        .padding(.vertical, 5)
                                } else if let logoUrlString = store.logo, // 1. ¿Existe store.logo (no es nil)?
                                          !logoUrlString.isEmpty,         // 2. ¿No está vacío?
                                          let url = URL(string: logoUrlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFit().frame(height: 150).cornerRadius(10)
                                                .padding(.vertical, 5)
                                        case .failure:
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .resizable().scaledToFit().frame(height: 100).cornerRadius(10)
                                                .foregroundColor(.gray)
                                            Text("Not possible to load image.")
                                        case .empty:
                                            ProgressView().frame(height: 150)
                                        @unknown default:
                                            EmptyView().frame(height: 150)
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo.badge.plus")
                                        .resizable().scaledToFit().frame(height: 100).cornerRadius(10)
                                        .foregroundColor(.gray)
                                    Text("There is no image yet. Please select one.")
                                }

                                PhotosPicker("Select an image", selection: $selectedItem, matching: .images)
                                    .onChange(of: selectedItem) { newItem in
                                        Task {
                                            selectedImage = nil
                                            newBase64Image = nil
                                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                                               let uiImage = UIImage(data: data) {
                                                selectedImage = uiImage
                                                newBase64Image = data.base64EncodedString()
                                            }
                                        }
                                    }
                            }

            Button("Update Store", action: updateStore)
                .frame(maxWidth: .infinity)
            
            Button("Delete Store", action: deleteStore)
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)

            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Update Store")
        .disabled(isCreating)
            .overlay(alignment: .center) {
                if isCreating {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Your store is being updated in the background")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                        Button("Close") {
                            isCreating = false // Oculta el mensaje
                            dismiss() //Navega a la anterior
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.opacity)
                }
            }
            .onAppear {
                           nameInput = store.name
                           nitInput = store.nit
                           addressInput = store.address
                           latitudeInput = String(store.latitude)
                           longitudeInput = String(store.longitude)
                if let opensDate = Self.timeFormatter.date(from: store.opens_at) {
                                    opensAtDate = opensDate
                                } else {
                                    // Fallback si el parseo falla, podrías poner una hora por defecto o manejar el error
                                    print("Error al parsear opens_at: \(store.opens_at)")
                                    // opensAtDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                                }
                                
                                if let closesDate = Self.timeFormatter.date(from: store.closes_at) {
                                    closesAtDate = closesDate
                                } else {
                                    print("Error al parsear closes_at: \(store.closes_at)")
                                    // closesAtDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
                                }
                           // `selectedImage` and `newBase64Image` remain nil unless a new image is picked
                print("🔄 UpdateStoreView onAppear: HomeController instance = \(Unmanaged.passUnretained(homeController).toOpaque()) for store: \(store.name)")

                       }
        .alert(alertTitle, isPresented: $showCreatedAlert) {
            Button("OK") {
                onDismissAfterUpdate?()
                dismiss()
            }
        }
    }

    func updateStore() {
        isCreating = true
        errorMessage = nil
        
        guard let lat = Double(latitudeInput.replacingOccurrences(of: ",", with: ".")),
              let lon = Double(longitudeInput.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Error converting latitude or longitude to Double"
            isCreating = false
            return
        }

        let opensAtString = Self.timeFormatter.string(from: opensAtDate)
        let closesAtString = Self.timeFormatter.string(from: closesAtDate)

        Task {
            await controller.updateStore(store_id: store.store_id, name: nameInput, nit: nitInput, imageBase64: newBase64Image, address: addressInput, latitude: lat, longitude: lon, opens_at: opensAtString, closes_at: closesAtString)
            
            if let errorMsg = controller.errorMessage {
                alertTitle = "Falló la Actualización ❌"
            } else {
                alertTitle = "Actualización Iniciada ✅"
                alertMessage = controller.successMessage ?? "La tienda se actualizó localmente y se sincronizará si es necesario."
                homeController.loadInitialData() // Actualizar datos en HomeView para reflejar cambios
            }
            self.isCreating = false
            showCreatedAlert = true
        }

    }
    
    func deleteStore() {
        Task {
            await controller.deleteStore(store_id: store.store_id)
            
            if let errorMsg = controller.errorMessage {
                alertTitle = "Falló la Eliminación ❌"
                errorMessage = errorMsg
            } else {
                alertTitle = "Eliminación Iniciada 🗑️"
                homeController.loadInitialData()
            }
            showCreatedAlert = true
        }
    }
}
