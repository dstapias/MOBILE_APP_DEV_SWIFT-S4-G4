import SwiftUI
import PhotosUI

struct CreateProductView: View {
    let store: Store
    @ObservedObject var controller: ProductController
    
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var selectedProductType: ProductType = .product
    @State private var score: String = ""
    @State private var unitPrice: String = ""
    @State private var successMessage: String?
    @State private var errorMessage: String?

    // Image handling
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var base64Image: String? = nil
    
    @State private var isCreating: Bool = false
    @State private var showCreatedAlert: Bool = false
    
    @State private var nameInput: String = ""
    @State private var detailInput: String = ""
    @State private var scoreInput: String = "0" // Fijo en 0
    @State private var unitPriceInput: String = ""


    var body: some View {
        Form {
            Section(header: Text("Product Info")) {
                
                // Nombre (máx 50 caracteres)
                TextField("Name", text: $nameInput)
                    .onChange(of: nameInput) { newValue in
                        if newValue.count > 50 {
                            nameInput = String(newValue.prefix(50))
                        }
                    }

                // Detalle (máx 50 caracteres)
                TextField("Detail", text: $detailInput)
                    .onChange(of: detailInput) { newValue in
                        if newValue.count > 50 {
                            detailInput = String(newValue.prefix(50))
                        }
                    }

                // Tipo de producto
                Picker("Product Type", selection: $selectedProductType) {
                    ForEach(ProductType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                // Score fijo en 0
                TextField("Score", text: .constant("0"))
                    .disabled(true)
                    .foregroundColor(.gray)

                TextField("Price (COP)", text: $unitPriceInput)
                    .keyboardType(.numberPad)
                    .onChange(of: unitPriceInput) { newValue in
                        let onlyDigits = newValue.filter { $0.isNumber }

                        // Permitir que el usuario escriba libremente hasta 6 dígitos
                        if onlyDigits.count <= 6 {
                            unitPriceInput = onlyDigits
                        } else {
                            unitPriceInput = String(onlyDigits.prefix(6))
                        }
                    }
            }

            Section(header: Text("Product Image")) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(10)
                }

                PhotosPicker("Select Image", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                base64Image = data.base64EncodedString()
                            }
                        }
                    }
            }

            Button("Create Product", action: submitProduct)
                .frame(maxWidth: .infinity)

            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("New Product")
        .disabled(isCreating)
            .overlay(alignment: .center) {
                if isCreating {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Your product is being created in the background")
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
        .alert("✅ Product Created", isPresented: $showCreatedAlert) {
            Button("OK") {
                dismiss() // Go back to ProductView
            }
        }
    }

    func submitProduct() {
        guard let price = Double(unitPriceInput), (5000...100000).contains(price),
              let base64 = base64Image else {
            errorMessage = "Please fill all fields correctly. Price must be between 5,000 and 100,000 COP."
            return
        }

        // Score fijo en 0
        let parsedScore = 0.0

        isCreating = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                do {
                    // Simulación de demora (20 segundos)
                    try await Task.sleep(nanoseconds: 20_000_000_000)
                    try await controller.createProduct(
                        name: nameInput,
                        detail: detailInput,
                        imageBase64: base64,
                        productType: selectedProductType.rawValue,
                        score: parsedScore,
                        unitPrice: price
                    )

                    DispatchQueue.main.async {
                        controller.loadProductsAndTags()
                        isCreating = false
                        showCreatedAlert = true
                    }

                } catch {
                    DispatchQueue.main.async {
                        isCreating = false
                        errorMessage = "❌ Failed to create product."
                    }
                }
            }
        }
    }
}
