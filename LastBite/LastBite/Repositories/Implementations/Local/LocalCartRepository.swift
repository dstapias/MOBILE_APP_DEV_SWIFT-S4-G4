//
//  LocalCartRepository.swift
//  LastBite
//
//  Created by Andrés Romero on 23/04/25.
//

import Foundation
import RealmSwift

@MainActor
/// Repositorio local basado en Realm que implementa `CartRepository`
final class LocalCartRepository: CartRepository {

    // MARK: – Initializer (failable para detectar errores de apertura)
    init?() {
        do { _ = try Realm() }               // abre la base por defecto
        catch {
            print("❌ CRITICAL REALM ERROR: \(error.localizedDescription)")
            return nil
        }
        print("🛒 LocalCartRepository initialized (Realm OK).")
    }

    // MARK: – Helper
    private func realmInstance() throws -> Realm {
        do { return try Realm() }             // sincrónico; seguro en cualquier actor
        catch {
            print("❌ REALM ERROR: \(error.localizedDescription)")
            throw ServiceError.invalidResponseFormat
        }
    }
    
    // Función temporal que puedes llamar desde un botón o un punto específico
    func printRealmCartItems() {
        print("--- Contenido RealmCartItem ---")
        do {
            let realm = try Realm() // Obtiene instancia síncrona
            let items = realm.objects(RealmCartItem.self)
            if items.isEmpty {
                print("No hay items en Realm.")
            } else {
                for item in items {
                    // Imprime las propiedades que te interesen
                    print("ID: \(item.productId), CartID: \(item.cartId), Name: \(item.name), Qty: \(item.quantity), Price: \(item.price), sync?: \(item.needsSync), deleted: \(item.isDeletedLocally)")
                }
            }
        } catch {
            print("Error al leer Realm: \(error.localizedDescription)")
        }
        print("-------------------------------")
    }

    func printRealmCarts() {
        print("--- Contenido RealmCarts ---")
        do {
            let realm = try Realm() // Obtiene instancia síncrona
            let items = realm.objects(RealmCart.self)
            if items.isEmpty {
                print("No hay Crats en Realm.")
            } else {
                for item in items {
                    // Imprime las propiedades que te interesen
                    print("CartID: \(item.cartId), sTATUS: \(item.status), DateC: \(item.creationDate), Userid: \(item.userId)")
                }
            }
        } catch {
            print("Error al leer Realm: \(error.localizedDescription)")
        }
        print("-------------------------------")
    }
    // Llama a esta función donde quieras verificar, por ejemplo:
    // Button("Imprimir Carrito Realm") { printRealmCartItems() }

    // MARK: – CartRepository con persistencia local
    func fetchActiveCart(for userId: Int) async throws -> Cart {
        printRealmCartItems()
        printRealmCarts()
        let realm = try realmInstance()

        guard let rc = realm.objects(RealmCart.self)
                .filter("userId == %@ AND status IN %@",
                        userId, ["Status.ACTIVE","Status.PAYMENT_PROGRESS","Status.PAYMENT_DECLINED"])
                .first
        else { throw ServiceError.notFound }

        let frozen = rc.freeze()              // seguro entre hilos/actores
        return Cart(
            cart_id:     frozen.cartId,
            creation_date: frozen.creationDate,
            status:      frozen.status,
            status_date: frozen.statusDate,
            user_id:     frozen.userId
        )
    }

    func updateCartStatus(cartId: Int, status: String, userId: Int) async throws {
        printRealmCartItems()

        let realm = try realmInstance()

        try realm.write {
            guard
                let rc = realm.object(ofType: RealmCart.self, forPrimaryKey: cartId),
                !rc.isInvalidated
            else { throw ServiceError.notFound }

            rc.status      = status
            rc.statusDate  = ISO8601DateFormatter().string(from: Date())
        }
    }

    func fetchCartProducts(for cartId: Int) async throws -> [CartProduct] {
        printRealmCartItems()

        let realm = try realmInstance()

        // ← CONVERSIÓN A ARRAY ANTES DE MAPEAR
        let items = Array(
            realm.objects(RealmCartItem.self)
                 .filter("cartId == %@ AND isDeletedLocally == false", cartId)
                 .freeze()
        )

        return items.map {
            CartProduct(
                cart_id:   $0.cartId,
                product_id:$0.productId,
                quantity:  $0.quantity
            )
        }
    }

    func fetchDetailedCartProducts(for cartId: Int) async throws -> [DetailedCartProduct] {
        printRealmCartItems()

        let realm = try realmInstance()

        // 1. Obtén y congela
        let frozen = realm.objects(RealmCartItem.self)
                          .filter("cartId == %@ AND isDeletedLocally == false", cartId)
                          .freeze()

        // 2. Convierte inmediatamente a Array
        let items = Array(frozen)

        // 3. Mapea a structs (ya no hay referencia a Realm)
        return items.map {
            DetailedCartProduct(
                product_id:  $0.productId,
                name:        $0.name,
                detail:      $0.detail,
                quantity:    $0.quantity,
                unit_price:  $0.price,
                image:       $0.imageUrl
            )
        }
    }

    // MARK: – Mutaciones

    func addProductToCart(cartId: Int, product: Product, quantity: Int) async throws {
        printRealmCartItems()

        let realm = try realmInstance()
        let pk    = "\(cartId)-\(product.id)"          // clave compuesta

        try realm.write {
            if let item = realm.object(ofType: RealmCartItem.self, forPrimaryKey: pk) {
                guard !item.isInvalidated else { throw ServiceError.notFound }
                item.quantity += quantity
                item.name      = product.name
                item.detail    = product.detail
                item.price     = product.unit_price
                item.imageUrl  = product.image
            } else {
                let newItem       = RealmCartItem()
                newItem.cartId    = cartId
                newItem.productId = product.id
                newItem.quantity  = quantity
                newItem.name      = product.name
                newItem.detail    = product.detail
                newItem.price     = product.unit_price
                newItem.imageUrl  = product.image
                realm.add(newItem, update: .modified)
            }
        }
    }

    func updateProductQuantity(cartId: Int, productId: Int, quantity: Int) async throws {
        printRealmCartItems()

        let realm = try realmInstance()

        try realm.write {
            guard
                let item = realm.object(ofType: RealmCartItem.self, forPrimaryKey: productId),
                !item.isInvalidated
            else { throw ServiceError.notFound }
            item.quantity = quantity
            item.needsSync = true
        }
    }

    func removeProductFromCart(cartId: Int, productId: Int) async throws {
        printRealmCartItems()

        let realm = try realmInstance()
        try realm.write {
            guard
                let item = realm.object(ofType: RealmCartItem.self, forPrimaryKey: productId),
                !item.isInvalidated
            else { throw ServiceError.notFound }
            item.needsSync = true
            item.isDeletedLocally = true
        }
    }

    // MARK: – Opcionales de guardado masivo (útiles al sincronizar con API)
    func saveCart(_ cart: Cart) async throws {
        printRealmCartItems()

        let realm = try realmInstance()

        try realm.write {
            // Crear y poblar dentro de la transacción
            let rc              = RealmCart()
            rc.cartId           = cart.cart_id
            rc.creationDate     = cart.creation_date
            rc.status           = cart.status
            rc.statusDate       = cart.status_date
            rc.userId           = cart.user_id

            realm.add(rc, update: .modified)
        }
    }

    func saveDetailedProducts(_ list: [DetailedCartProduct], for cartId: Int) async throws {
        printRealmCartItems()

        guard !list.isEmpty else { return }

        let realm = try realmInstance()

        try realm.write {
            for dp in list {
                let obj        = RealmCartItem()
                obj.cartId     = cartId
                obj.productId  = dp.product_id
                obj.quantity   = dp.quantity
                obj.name       = dp.name
                obj.detail     = dp.detail
                obj.price      = dp.unit_price
                obj.imageUrl   = dp.image
                realm.add(obj, update: .modified)
            }
        }
    }
    
    func fetchItemsNeedingSync(for cartId: Int) async throws -> [RealmCartItem] {
           let realm = try realmInstance()
           print("💾 [LocalRepo] Fetching items needing sync for cart \(cartId)...")

           // Busca items del carrito especificado que necesiten sincronización
           let itemsToSync = realm.objects(RealmCartItem.self)
                                .filter("cartId == %@ AND needsSync == true", cartId)

           // Congela los resultados para pasarlos de forma segura
           let frozenItems = itemsToSync.freeze()
           print("   Found \(frozenItems.count) items needing sync.")
           // Devuelve un Array de los objetos congelados
           return Array(frozenItems)
       }

       /// Marca un item específico como sincronizado (o lo borra si estaba marcado para eliminar).
       func markItemAsSynced(productId: Int) async throws {
           let realm = try realmInstance()
           print("💾 [LocalRepo] Marking item \(productId) as synced...")

           try await realm.asyncWrite {
               guard let item = realm.object(ofType: RealmCartItem.self, forPrimaryKey: productId) else {
                    print("   ⚠️ [LocalRepo Write] Item \(productId) not found to mark as synced.")
                    return // No encontrado, no hay nada que hacer
               }
               guard !item.isInvalidated else {
                    print("   ⚠️ [LocalRepo Write] Item \(productId) invalidated before marking synced.")
                    return // Ya no es válido
               }

               // Verifica si estaba marcado para borrar
               if item.isDeletedLocally {
                   print("   Deleting locally deleted item \(productId) after successful API sync.")
                   realm.delete(item) // Elimina definitivamente de Realm
               } else {
                   // Si no estaba para borrar, simplemente quita la marca de sincronización
                   print("   Marking item \(productId) needsSync = false.")
                   item.needsSync = false
               }
           }
            print("   ✅ [LocalRepo] Item \(productId) marked as synced/deleted.")
       }
    
    func synchronizeCart(cartId: Int) async throws {}

}
