//
//  fireBaseService.swift
//  LastBite
//
//  Created by David Santiago on 23/04/25.
//

import Foundation
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService() // Singleton instance
    private init() {}

    /// Uploads base64 image data to Firebase Storage and returns the public URL.
    func uploadImageToFirebase(base64: String, fileName: String) async throws -> String {
        guard let imageData = Data(base64Encoded: base64) else {
            throw ServiceError.serializationError(NSError(domain: "Invalid Base64", code: 0))
        }

        let storageRef = Storage.storage().reference().child("products/\(fileName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
}
