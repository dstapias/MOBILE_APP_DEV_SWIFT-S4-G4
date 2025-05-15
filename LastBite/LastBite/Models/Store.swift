//
//  Store.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct Store: Codable, Identifiable, Equatable {
    let store_id: Int
    let nit: String
    let name: String
    let address: String
    let longitude: Double // Coordenadas como Double para precisión
    let latitude: Double  // Coordenadas como Double para precisión
    var logo: String?     // URL del logo, opcional (String?)
    let opens_at: String  // Cadena de texto para la hora, ej: "HH:mm:ss"
    let closes_at: String // Cadena de texto para la hora, ej: "HH:mm:ss"
    
    // Estos campos son comunes. Si tu API los devuelve, inclúyelos.
    // Si no, puedes omitirlos o mantenerlos comentados.
    // Asegúrate de que el JSON que decodificas coincida con estas propiedades.
    let created_at: String? // Cadena para fecha y hora, ej: formato ISO 8601
    let updated_at: String? // Cadena para fecha y hora, ej: formato ISO 8601

    // Conformidad con el protocolo Identifiable
    // SwiftUI usa 'id' para identificar de forma única los elementos en listas y ForEach.
    var id: Int {
        return store_id
    }

    // Conformidad con el protocolo Equatable
    // Esto permite comparar dos instancias de 'Store' para ver si son iguales.
    // Es crucial para que SwiftUI detecte cambios en los datos y actualice la UI.
    static func == (lhs: Store, rhs: Store) -> Bool {
        // Compara todos los campos que son relevantes para determinar si la tienda
        // ha cambiado visualmente o en sus datos fundamentales.
        return lhs.store_id == rhs.store_id &&
               lhs.nit == rhs.nit &&
               lhs.name == rhs.name &&
               lhs.address == rhs.address &&
               lhs.longitude == rhs.longitude &&
               lhs.latitude == rhs.latitude &&
               lhs.logo == rhs.logo && // Compara el logo (ahora opcional)
               lhs.opens_at == rhs.opens_at &&
               lhs.closes_at == rhs.closes_at &&
               lhs.created_at == rhs.created_at && // Compara si los tienes
               lhs.updated_at == rhs.updated_at   // Compara si los tienes
    }
    
    // CodingKeys son necesarios si los nombres de las propiedades en Swift
    // difieren de las claves en el JSON que recibes de tu API.
    // Si los nombres coinciden (ej. "store_id" en JSON es store_id en Swift),
    // no necesitas definirlos explícitamente para esos campos, Codable los manejará.
    // Si tu API usa snake_case (ej. "store_id") y tus propiedades Swift son camelCase (ej. storeId),
    // puedes configurar un `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`
    // en lugar de definir todos los CodingKeys.
    enum CodingKeys: String, CodingKey {
        case store_id // Asume que el JSON usa "store_id"
        case nit
        case name
        case address
        case longitude
        case latitude
        case logo
        case opens_at // Asume que el JSON usa "opens_at"
        case closes_at // Asume que el JSON usa "closes_at"
        case created_at // Asume que el JSON usa "created_at"
        case updated_at // Asume que el JSON usa "updated_at"
    }
}
