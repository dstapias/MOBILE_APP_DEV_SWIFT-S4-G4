import SwiftUI
import PhotosUI

struct CreateProductView: View {
    let store: Store
    @ObservedObject var controller: ProductController
    
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var productType: String = ""
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

    var body: some View {
        Form {
            Section(header: Text("Product Info")) {
                TextField("Name", text: $name)
                TextField("Detail", text: $detail)
                TextField("Product Type", text: $productType)
                TextField("Score", text: $score)
                    .keyboardType(.decimalPad)
                TextField("Price", text: $unitPrice)
                    .keyboardType(.decimalPad)
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
            guard let price = Double(unitPrice),
                  let parsedScore = Double(score),
                  let base64 = base64Image else {
                errorMessage = "Please fill all fields correctly."
                return
            }

            isCreating = true
            errorMessage = nil

            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    do {
                        //Este pedazo de codigo se deja para simular una demora y demostrar que no esta bloqueado el thread principal
                        try await Task.sleep(nanoseconds: 20_000_000_000)
                        try await controller.createProduct(
                            name: name,
                            detail: detail,
                            imageBase64: base64,
                            productType: productType,
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
