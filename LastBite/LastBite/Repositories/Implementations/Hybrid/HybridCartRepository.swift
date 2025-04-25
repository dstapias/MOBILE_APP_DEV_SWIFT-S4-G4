//
//  HybridCartRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 24/04/25.
//

import Foundation

// Repositorio "Orquestador" que implementa la estrategia "API + Guardado en Caché (Realm)"
final class HybridCartRepository: CartRepository {

    private let apiRepository: CartRepository // El repo que habla con la API
    private let localRepository: LocalCartRepository // El repo que habla con Realm

    // Inyecta ambos repositorios
    init(apiRepository: CartRepository, localRepository: LocalCartRepository) {
        self.apiRepository = apiRepository
        self.localRepository = localRepository
        print("📦 CachingCartRepository initialized.")
    }

    // MARK: - Implementación del Protocolo CartRepository

    func fetchActiveCart(for userId: Int) async throws -> Cart {
        do {
            // 1. Intenta obtener de la API PRIMERO
            let domainCart = try await apiRepository.fetchActiveCart(for: userId)

            // 2. Si API OK, guarda en local en segundo plano (como antes)
            Task.detached(priority: .utility) {
                try? await self.localRepository.saveCart(domainCart) // Usa try? para ignorar errores de guardado local si no son críticos
            }
            // 3. Devuelve el resultado de la API
            return domainCart

        } catch let error as ServiceError where error.isNetworkConnectionError { // <-- Captura error específico de red
            // 4. SI la API falló por conexión, INTENTA leer de LOCAL
            print("⚠️ API failed due to network, attempting to fetch from local Realm store...")
            do {
                // Llama al método del repositorio local (que ahora debe ser async throws también)
                let localCart = try await localRepository.fetchActiveCart(for: userId)
                print("✅ Fetched active cart from local store successfully.")
                return localCart // Devuelve el dato local como backup
            } catch let localError {
                // Si también falla localmente, relanza el error local o el original
                print("❌ Failed to fetch active cart from local store as well: \(localError.localizedDescription)")
                throw localError // O puedes relanzar el 'error' original de la API
            }
        } catch {
            // 5. Si la API falló por OTRA razón (ej. 404 Not Found, 500 Server Error), relanza el error original
            print("❌ API failed for non-network reason: \(error.localizedDescription). Not attempting local fetch.")
            throw error
        }
    }

    func updateCartStatus(cartId: Int, status: String, userId: Int) async throws {
        // 1. Intenta actualizar en la API
        try await apiRepository.updateCartStatus(cartId: cartId, status: status, userId: userId)

        // 2. Si API OK, intenta actualizar en local
        Task(priority: .utility) { @MainActor in
             do {
                 print("Updating cart status in realm...")
                try await self.localRepository.updateCartStatus(cartId: cartId, status: status, userId: userId)
             } catch {
                 print("⚠️ CachingCartRepository: Failed to update local cart status: \(error.localizedDescription)")
             }
         }
    }

    func fetchCartProducts(for cartId: Int) async throws -> [CartProduct] {
        
        
        do {
            // 1. Intenta obtener de la API
            let domainCartProducts = try await apiRepository.fetchCartProducts(for: cartId)

            // 2. Si API OK, intenta guardar en local (la versión básica)
            Task(priority: .utility) { @MainActor in
                // Necesitaríamos un método localRepository.saveCartProducts si quisiéramos guardar esta versión
                // Por ahora, asumimos que fetchDetailed es el importante para guardar
                print("ℹ️ CachingCartRepository: Basic cart products fetched from API, local cache not updated with this basic info.")
            }
            // 3. Devuelve resultado API
            return domainCartProducts
        }
        catch {
            print("⚠️ CachingCartRepository: Failed to fetch cart products from API: \(error.localizedDescription)")
            throw error
        }
    }

    // Dentro de CachingCartRepository.swift

    func fetchDetailedCartProducts(for cartId: Int) async throws -> [DetailedCartProduct] {
            do {
                print("SYNCHRONIZING CART")
                try await synchronizeCart(cartId: cartId)
                // 1. Intenta obtener de la API PRIMERO
                 print("🛒 CachingRepo: Attempting to fetch detailed products from API for cart \(cartId)...")
                let domainDetailedProducts = try await apiRepository.fetchDetailedCartProducts(for: cartId)
                 print("   ✅ CachingRepo: API fetch successful, \(domainDetailedProducts.count) items.")

                // 2. Si API OK, GUARDA en local en segundo plano
                Task.detached(priority: .utility) { @MainActor in // Ejecuta en MainActor por seguridad con Realm
                    do {
                        print("   💾 [BG Task] Saving \(domainDetailedProducts.count) detailed products locally...")
                        // Llama al método async de LocalCartRepository
                        try await self.localRepository.saveDetailedProducts(domainDetailedProducts, for: cartId)
                         print("   💾 [BG Task] Local save successful.")
                    } catch {
                        print("   ⚠️ [BG Task] CachingCartRepository: Failed to save detailed cart products locally: \(error.localizedDescription)")
                    }
                }
                // 3. Devuelve el resultado FRESCO de la API
                return domainDetailedProducts

            } catch let error as ServiceError where error.isNetworkConnectionError {
                // 4. SI la API falló por CONEXIÓN, intenta leer de LOCAL como backup
                 print("⚠️ CachingRepo: API fetch failed due to network error. Attempting local fallback...")
                 do {
                     // Llama al método async de LocalCartRepository para leer
                     let localDetailedProducts = try await localRepository.fetchDetailedCartProducts(for: cartId)
                     print("   ✅ CachingRepo: Fetched \(localDetailedProducts.count) items from local store as backup.")
                     // Devuelve los datos LOCALES como backup
                     return localDetailedProducts
                 } catch let localError {
                      print("   ❌ CachingRepo: Failed to fetch from local store as well: \(localError.localizedDescription). Rethrowing original API error.")
                     // Si la lectura local también falla, relanza el error ORIGINAL de la API
                     throw error
                 }
            } catch {
                // 5. SI la API falló por OTRA razón (ej: 404, 500, error de decodificación de API),
                //    NO intentamos leer local y simplemente relanzamos el error de la API.
                 print("❌ CachingRepo: API fetch failed for non-network reason: \(error.localizedDescription). Not attempting local fallback.")
                throw error
            }
        } 

    // --- MÉTODO addProductToCart (Local First) ---
        func addProductToCart(cartId: Int, product: Product, quantity: Int) async throws {
            print("🛒 HybridRepo: AddProduct - Attempting LOCAL write first...")
            // 1. Intenta añadir/actualizar en LOCAL PRIMERO (y marcar needsSync=true)
            try await localRepository.addProductToCart(cartId: cartId, product: product, quantity: quantity)
            print("   ✅ HybridRepo: Local add/update successful.")

            // 2. Si local OK, INTENTA sincronizar con API en segundo plano
            Task.detached(priority: .utility) {
                do {
                    print("   ☁️ [BG Task] Attempting API add/update...")
                    // Llama al método API correspondiente
                    try await self.apiRepository.addProductToCart(cartId: cartId, product: product, quantity: quantity) // Asume que API necesita quantity total o ajusta
                     print("   ☁️ [BG Task] API add/update successful. Item should be marked synced locally if API call succeeded AFTER sync method.")
                     // Opcional: podrías llamar a markAsSynced aquí si la API tuvo éxito,
                     // pero es mejor dejarlo para el synchronizeCart explícito.
                } catch {
                    print("   ⚠️ [BG Task] API add/update FAILED (needs sync later): \(error.localizedDescription)")
                    // No hacemos nada más, el item ya está marcado localmente como needsSync=true
                }
            }
            // Retorna éxito inmediatamente después de la escritura local exitosa
        }

        // --- MÉTODO updateProductQuantity (Local First) ---
        func updateProductQuantity(cartId: Int, productId: Int, quantity: Int) async throws {
             print("🛒 HybridRepo: UpdateQuantity - Attempting LOCAL write first...")
            // 1. Intenta actualizar en LOCAL PRIMERO (y marcar needsSync=true)
            try await localRepository.updateProductQuantity(cartId: cartId, productId: productId, quantity: quantity)
             print("   ✅ HybridRepo: Local quantity update successful.")

            // 2. Si local OK, INTENTA sincronizar con API en segundo plano
             Task.detached(priority: .utility) {
                  do {
                       print("   ☁️ [BG Task] Attempting API quantity update...")
                      try await self.apiRepository.updateProductQuantity(cartId: cartId, productId: productId, quantity: quantity)
                       print("   ☁️ [BG Task] API quantity update successful.")
                       // Opcional: Podrías intentar marcar como sincronizado aquí
                       // try? await self.localRepository.markItemAsSynced(productId: productId)
                  } catch {
                      print("   ⚠️ [BG Task] API quantity update FAILED (needs sync later): \(error.localizedDescription)")
                  }
              }
              // Retorna éxito inmediatamente
        }

        // --- MÉTODO removeProductFromCart (Local First) ---
        func removeProductFromCart(cartId: Int, productId: Int) async throws {
            print("ACAAAAAAAAAAAAAAAAAA")
             print("🛒 HybridRepo: RemoveProduct - Attempting LOCAL mark first...")
            // 1. Intenta MARCAR como borrado en LOCAL PRIMERO (y marcar needsSync=true)
            //    (Asegúrate que LocalCartRepository.removeProductFromCart haga esto)
            try await localRepository.removeProductFromCart(cartId: cartId, productId: productId)
             print("   ✅ HybridRepo: Local mark for removal successful.")

            // 2. Si local OK, INTENTA sincronizar con API en segundo plano
            Task.detached(priority: .utility) {
                do {
                     print("   ☁️ [BG Task] Attempting API remove...")
                    try await self.apiRepository.removeProductFromCart(cartId: cartId, productId: productId)
                     print("   ☁️ [BG Task] API remove successful.")
                     // Si API OK, ahora sí borra localmente (o márcalo sincronizado)
                     try? await self.localRepository.markItemAsSynced(productId: productId) // Esto lo borrará si está marcado
                } catch {
                     print("   ⚠️ [BG Task] API remove FAILED (needs sync later): \(error.localizedDescription)")
                    
                }
            }
             // Retorna éxito inmediatamente
        }
    
    func synchronizeCart(cartId: Int) async throws {
            print("🔄 CachingRepo: Starting cart synchronization for cart \(cartId)...")

            // 1. Obtener items locales que necesitan sincronización
            //    Necesitamos un método en LocalCartRepository para esto
            let itemsToSync = try await localRepository.fetchItemsNeedingSync(for: cartId)
             print("   Sync: Found \(itemsToSync.count) items needing sync.")

            guard !itemsToSync.isEmpty else {
                print("   Sync: No items to sync.")
                return // Nada que hacer
            }

            // 2. Iterar e intentar sincronizar cada uno con la API
            var syncErrors: [Error] = []
            for item in itemsToSync {
                do {
                    // Llama al método API apropiado basado en el estado local
                    if item.isDeletedLocally { // Asume que añadiste este campo a RealmCartItem
                        print("   Sync: Attempting to remove item \(item.productId) via API...")
                        try await apiRepository.removeProductFromCart(cartId: item.cartId, productId: item.productId)
                    } else if item.quantity > 0 { // Asume que 'add' y 'update' se manejan con updateQuantity o un endpoint inteligente
                         print("   Sync: Attempting to update quantity for item \(item.productId) to \(item.quantity) via API...")
                         // Necesitarías una forma de saber si fue un add o update, o un endpoint que haga upsert.
                         // Llamaremos a updateQuantity por ahora. ¡ESTO PUEDE NECESITAR AJUSTES!
                         try await apiRepository.updateProductQuantity(cartId: item.cartId, productId: item.productId, quantity: item.quantity)
                    }
                    // else: Podría haber otros estados?

                    // 3. Si la API tuvo éxito, marca el item local como sincronizado
                    print("      ✅ API Sync successful for item \(item.productId). Marking as synced locally.")
                     try await localRepository.markItemAsSynced(productId: item.productId) // Necesitas este método en LocalCartRepository

                } catch {
                     print("      ❌ API Sync FAILED for item \(item.productId): \(error.localizedDescription)")
                     syncErrors.append(error)
                     // Decide si continuar con los demás o detenerte aquí
                }
            }

            // 4. Si hubo algún error durante la sincronización, lanza un error general
            if !syncErrors.isEmpty {
                 print("   Sync: Finished with \(syncErrors.count) errors.")
                // Lanza el primer error encontrado o un error genérico
                throw syncErrors.first ?? ServiceError.syncFailed // Necesitas definir ServiceError.syncFailed
            } else {
                 print("   Sync: All items synchronized successfully.")
            }
        }
}
