//
//  StoreController.swift
//  LastBite
//
//  Created by Andrés Romero on 13/05/25.
//

import Foundation

class StoreController: ObservableObject {
    private let storeRepository: StoreRepository
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    init(
        storeRepository: StoreRepository
    ) {
        self.storeRepository = storeRepository
        print("📦 StoreController initialized")
    }
    
    @MainActor
    func updateStore(
        store_id: Int,
        name: String,
        nit: String,
        imageBase64: String?,
        address: String,
        latitude: Double,
        longitude: Double,
        opens_at: String,
        closes_at: String
    ) async throws {
        print("🚀 Starting store update...")
        var finalImageURLForBackend: String? = nil // Esta será la URL para enviar al backend

        do {
            // 1. Subir imagen a Firebase y obtener URL
            // Paso 1: Subir la imagen a Firebase SI se proporcionó una nueva imagen Base64 VÁLIDA.
                       if let potentialBase64String = imageBase64,
                          !potentialBase64String.isEmpty,
                          // Añadimos una comprobación para asegurarnos de que no es una URL
                          !potentialBase64String.starts(with: "http://"),
                          !potentialBase64String.starts(with: "https://") {
                           
                           print("📸 StoreController: Attempting to upload new image via FirebaseService with presumed Base64 data (length: \(potentialBase64String.count))...")
                           let fileName = "\(UUID().uuidString).jpg" // O .png, según tu formato
                           
                           finalImageURLForBackend = try await FirebaseService.shared.uploadImageToFirebase(base64: potentialBase64String, fileName: fileName)
                           print("📸 StoreController: New image uploaded. Firebase URL: \(finalImageURLForBackend ?? "No URL returned")")
                       
                       } else if let receivedString = imageBase64, !receivedString.isEmpty {
                           // Si imageBase64 no estaba vacío pero parecía una URL o no pasó la validación de Base64.
                           print("ℹ️ StoreController: imageBase64 parameter received a string that is likely a URL or not valid Base64 ('\(receivedString.prefix(100))...'). Skipping Firebase upload, assuming no new image or incorrect data passed.")
                           // finalImageURLForBackend permanece nil, lo que significa "no cambiar el logo".
                       } else {
                           print("ℹ️ StoreController: No new image base64 provided (it was nil or empty). Skipping Firebase upload.")
                           // finalImageURLForBackend permanece nil.
                       }
            // 2. Crear solicitud con la URL obtenida
            let storeRequest = StoreUpdateRequest(
                    name: name,
                nit: nit,
                address: address,
                longitude: longitude,
                latitude: latitude,
                logo: finalImageURLForBackend,
                opens_at: opens_at,
                closes_at: closes_at,
            )

            // 3. Enviar al backend
            try await storeRepository.updateStore(storeRequest, store_id: store_id)
            print("✅ Store updated successfully.")
            self.successMessage = "Store updated successfully."
            self.errorMessage = nil

        } catch let error as ServiceError {
            print("❌ Service error updating store: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.successMessage = nil
            throw error

        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            self.errorMessage = "Unexpected error occurred."
            self.successMessage = nil
            throw error
        }
    }
    
    
    @MainActor
    func deleteStore(
        store_id: Int
    ) async throws {
        print("🚀 Deleting store...")

        do {
            // 3. Enviar al backend
            try await storeRepository.deleteStore(store_id: store_id)
            print("✅ Store deleted successfully.")
            self.successMessage = "Store deleted successfully."
            self.errorMessage = nil

        } catch let error as ServiceError {
            print("❌ Service error deleting store: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.successMessage = nil
            throw error

        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            self.errorMessage = "Unexpected error occurred."
            self.successMessage = nil
            throw error
        }
    }
    
    @MainActor
    func fetchStoreById(store_id: Int) async throws -> Store {
        do {
            return try await storeRepository.fetchStoreById(store_id: store_id)
        }
    }
    
}
