//
//  StoreUpdateRequest.swift
//  LastBite
//
//  Created by Andrés Romero on 13/05/25.
//

import Foundation

// Este struct representa el CUERPO JSON que se envía al backend para actualizar una tienda.
// No incluye 'store_id' porque ese ID se usa en la URL del endpoint.
struct StoreUpdateRequest: Encodable {
    let name: String
    let nit: String
    let address: String
    let longitude: Double
    let latitude: Double
    let logo: String?       // URL de la nueva imagen (de Firebase), o nil si no se actualiza el logo.
    let opens_at: String    // Cadena de texto para la hora, ej: "HH:mm:ss"
    let closes_at: String   // Cadena de texto para la hora, ej: "HH:mm:ss"
    
    // Los campos como created_at y updated_at generalmente son manejados
    // por el backend y no se envían en una solicitud de actualización.
}
