import SwiftUI
import PhotosUI

struct CreateStoreView: View {
    @ObservedObject var controller: StoreController
    @ObservedObject var homeController: HomeController
    var onDismissAfterCreate: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String = ""
    @State private var nitInput: String = ""
    @State private var addressInput: String = ""
    @State private var latitudeInput: String = ""
    @State private var longitudeInput: String = ""
    @State private var opensAtDate: Date = Date()
    @State private var closesAtDate: Date = Date()

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var newBase64Image: String? = nil

    @State private var isCreating: Bool = false
    @State private var showCreatedAlert: Bool = false
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(controller: StoreController,
         homeController: HomeController,
         onDismissAfterCreate: (() -> Void)? = nil) {
        self.controller = controller
        self.homeController = homeController
        self.onDismissAfterCreate = onDismissAfterCreate
    }

    var body: some View {
        Form {
            Section(header: Text("Store Info")) {
                TextField("Name", text: $nameInput)
                    .onChange(of: nameInput) { newValue in
                        if newValue.count > 50 {
                            nameInput = String(newValue.prefix(50))
                        }
                    }
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
                    .keyboardType(.numbersAndPunctuation)
                TextField("Longitude", text: $longitudeInput)
                    .keyboardType(.numbersAndPunctuation)
                DatePicker("Opens At", selection: $opensAtDate, displayedComponents: .hourAndMinute)
                DatePicker("Closes At", selection: $closesAtDate, displayedComponents: .hourAndMinute)
            }

            Section(header: Text("Store Image")) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .foregroundColor(.gray)
                    Text("Selecciona una imagen")
                }

                PhotosPicker("Select Image", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                newBase64Image = data.base64EncodedString()
                            }
                        }
                    }
            }

            Section {
                Button("Create Store", action: createStore)
                    .frame(maxWidth: .infinity)
                    .disabled(nameInput.isEmpty || addressInput.isEmpty)
            }

            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
            }
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Create Store")
        .disabled(isCreating)
        .overlay(alignment: .center) {
            if isCreating {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Creating store...")
                    Button("Cancel") {
                        isCreating = false
                        dismiss()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Inicializar valores si es necesario
        }
        .alert(alertTitle, isPresented: $showCreatedAlert) {
            Button("OK") {
                onDismissAfterCreate?()
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }

    func createStore() {
        isCreating = true
        errorMessage = nil
        successMessage = nil

        guard let lat = Double(latitudeInput.replacingOccurrences(of: ",", with: ".")),
              let lon = Double(longitudeInput.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Lat/Lon inválidos"
            isCreating = false
            return
        }

        let opens = Self.timeFormatter.string(from: opensAtDate)
        let closes = Self.timeFormatter.string(from: closesAtDate)

        Task { @MainActor in
            do {
                try await controller.createStore(
                    name: nameInput,
                    nit: nitInput,
                    address: addressInput,
                    latitude: lat,
                    longitude: lon,
                    opens_at: opens,
                    closes_at: closes,
                    imageBase64: newBase64Image
                )
                successMessage = "Store created successfully"
                alertTitle = "Creación iniciada ✅"
                alertMessage = successMessage ?? ""
                homeController.loadInitialData()
            } catch {
                errorMessage = error.localizedDescription
                alertTitle = "Error creando tienda ❌"
                alertMessage = errorMessage ?? ""
            }
            isCreating = false
            showCreatedAlert = true
        }
    }
}

