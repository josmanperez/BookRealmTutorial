//
//  User.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 19/4/22.
//

import Foundation
import RealmSwift

class User: Object {
    @Persisted(primaryKey: true) var _id: String = ""
    @Persisted var _partition: String = ""
    @Persisted var providerType: ProviderType?
    @Persisted var userName: String?
    @Persisted var userPreferences: UserPreferences?
    @Persisted var registered: Bool
    @Persisted var favoriteBooks: List<ObjectId>
}

enum ProviderTypeEnum: String, PersistableEnum {
    case anon = "anon-user"
    case userpass = "local-userpass"
}

class ProviderType: EmbeddedObject {
    @Persisted var id: String?
    @Persisted var provider_type: ProviderTypeEnum?
}

class UserPreferences: EmbeddedObject {
    @Persisted var displayName: String?
}
