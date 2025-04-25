//
//  ServiceError.swift
//  LastBite
//
//  Created by Andrés Romero on 15/04/25.
//

import Foundation

// Define un Error personalizado para respuestas inesperadas del servidor
enum ServiceError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case noData
    case badServerResponse(statusCode: Int)
    case decodingError(Error)
    case serializationError(Error)
    case invalidResponseFormat // Específico para createOrder si no viene el ID
    case missingCredentials             // Para email/password vacíos
     case authenticationError(Error)     // Para errores de Firebase Auth
     case missingEmailForPasswordReset // Para reset password
     case missingPhoneNumber           // Para enviar código SMS
     case missingVerificationId        // Para verificar código SMS
     case missingAreaId                // Para registro final
     case backendRegistrationFailed(statusCode: Int, message: String?)
    case notFound
    case syncFailed
    case emptyOffline

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The server URL was invalid."
        case .requestFailed(let error): return "Network request failed: \(error.localizedDescription)"
        case .noData: return "No data received from the server."
        case .badServerResponse(let code): return "Server returned an error: HTTP \(code)."
        case .decodingError(let error): return "Failed to decode server response: \(error.localizedDescription)"
        case .serializationError(let error): return "Failed to serialize request body: \(error.localizedDescription)"
        case .invalidResponseFormat: return "Server response format was invalid."
        case .missingCredentials: return "Email and password cannot be empty."
                case .authenticationError(let error): return "Authentication failed: \(error.localizedDescription)"
                case .missingEmailForPasswordReset: return "Please enter your email to reset the password."
                case .missingPhoneNumber: return "Phone number is required."
                case .missingVerificationId: return "Verification ID is missing. Please request a new code."
                case .missingAreaId: return "User area selection is missing."
                case .backendRegistrationFailed(let code, let msg): return "Backend registration failed (Status: \(code)). \(msg ?? "")"
        case .notFound: return "You are offline and we have no cart info. You may have a cart saved online Check connection and try again."
        case .emptyOffline: return "You are offline and can't add items to your cart. Check connection and try again."
        case .syncFailed: return "There was an error trying to sync your cart. Please veirfy your internet connection and try again."
        }
    }
    
    var isNetworkConnectionError: Bool {
            if case .requestFailed(let underlyingError) = self {
                let nsError = underlyingError as NSError
                // Códigos comunes de error de red en URLSession/NSURLErrorDomain
                return [
                    NSURLErrorNotConnectedToInternet,
                    NSURLErrorNetworkConnectionLost,
                    NSURLErrorCannotConnectToHost,
                    NSURLErrorTimedOut
                    // Añade otros códigos relevantes si los identificas
                ].contains(nsError.code)
            }
            return false
        }
}
