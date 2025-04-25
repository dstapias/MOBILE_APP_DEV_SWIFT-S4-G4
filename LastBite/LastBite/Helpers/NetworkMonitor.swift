//
//  NetworkMonitor.swift
//  LastBite
//
//  Created by Andrés Romero on 24/04/25.
//

import Foundation
import Network // <-- Importa el framework Network
import Combine // Necesario para ObservableObject

// Clase ObservableObject para monitorear el estado de la red
@MainActor // Publica cambios en el hilo principal
class NetworkMonitor: ObservableObject {

    // El monitor que observa los cambios de la red
    private let monitor: NWPathMonitor

    // Una cola de background para que el monitor no bloquee el hilo principal
    private let queue: DispatchQueue

    // Propiedad publicada que indica si hay conexión (true) o no (false)
    // Empieza como false hasta que el monitor confirme el estado.
    @Published var isConnected: Bool = false

    init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkMonitorQueue", qos: .background)

        // Configura el manejador que se llamará cada vez que cambie la ruta de red
        monitor.pathUpdateHandler = { [weak self] path in
            // Accede al estado de la ruta (.satisfied significa que hay conexión usable)
            let connected = path.status == .satisfied

            // Actualiza la propiedad @Published en el hilo principal
            DispatchQueue.main.async {
                 if self?.isConnected != connected { // Solo actualiza si el estado cambió
                     print("🌐 Network Status Changed: \(connected ? "Connected" : "Disconnected")")
                     self?.isConnected = connected
                 }
            }
        }
        print("🚦 NetworkMonitor Initialized.")
        // Inicia el monitoreo
        monitor.start(queue: queue)
    }

    // Opcional pero buena práctica: Detener el monitor cuando el objeto se desinicialice
    deinit {
        print("🚦 NetworkMonitor Deinitialized, cancelling monitor.")
        monitor.cancel()
    }
}
