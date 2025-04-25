//
//  RealmCart.swift
//  LastBite
//
//  Created by Andrés Romero on 23/04/25.
//

import RealmSwift

class RealmCart: Object {
    @Persisted(primaryKey: true) var cartId: Int        // equivale a cart_id
    @Persisted var creationDate: String                  // equivale a creation_date
    @Persisted var status: String                        // equivale a status
    @Persisted var statusDate: String                    // equivale a status_date
    @Persisted var userId: Int                           // equivale a user_id
}
