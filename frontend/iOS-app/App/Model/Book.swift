//
//  Book.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 25/4/22.
//

import Foundation
import RealmSwift

class Book: Object {
    @Persisted(primaryKey: true) var _id: ObjectId

    @Persisted var _partition: String = ""

    @Persisted var accessInfo: AccessInfo?

    @Persisted var identifier: String?

    @Persisted var saleInfo: SalesInfo?

    @Persisted var selfLink: String?

    @Persisted var volumeInfo: VolumeInfo?
}

class AccessInfo: EmbeddedObject {
    @Persisted var accessViewStatus: String?

    @Persisted var country: String?

    @Persisted var embeddable: Bool?

    @Persisted var epub: EPub?

    @Persisted var pdf: PDF?

    @Persisted var publicDomain: Bool?

    @Persisted var quoteSharingAllowed: Bool?

    @Persisted var textToSpeechPermission: String?

    @Persisted var viewability: String?

    @Persisted var webReaderLink: String?
}

class EPub: EmbeddedObject {
    @Persisted var acsTokenLink: String?

    @Persisted var downloadLink: String?

    @Persisted var isAvailable: Bool?
}

class PDF: EmbeddedObject {
    @Persisted var acsTokenLink: String?

    @Persisted var isAvailable: Bool?
}

class SalesInfo: EmbeddedObject {
    @Persisted var buyLink: String?

    @Persisted var country: String?

    @Persisted var isEbook: Bool?

    @Persisted var listPrice: ListPrice?

    @Persisted var offers: List<Offers>

    @Persisted var retailPrice: RetailPrice?

    @Persisted var saleability: String?
}

class ListPrice: EmbeddedObject {
    @Persisted var amount: Double?

    @Persisted var currencyCode: String?
}

class Offers: EmbeddedObject {
    @Persisted var finskyOfferType: Int?

    @Persisted var listPrice: OfferListPrice?

    @Persisted var retailPrice: OfferRetailPrice?
}

class OfferListPrice: EmbeddedObject {
    @Persisted var amountInMicros: Int?

    @Persisted var currencyCode: String?
}

class OfferRetailPrice: EmbeddedObject {
    @Persisted var amountInMicros: Int?

    @Persisted var currencyCode: String?
}

class RetailPrice: EmbeddedObject {
    @Persisted var amount: Double?

    @Persisted var currencyCode: String?
}

class VolumeInfo: EmbeddedObject {
    @Persisted var authors: List<String>

    @Persisted var averageRating: Double?

    @Persisted var categories: List<String>

    @Persisted var imageLinks: imageLinks?

    @Persisted var industryIdentifiers: List<IndustryIdentifiers>

    @Persisted var language: String?

    @Persisted var publishedDate: String?

    @Persisted var publisher: String?

    @Persisted var ratingsCount: Int?

    @Persisted var readingModes: ReadingModes?

    @Persisted var subtitle: String?

    @Persisted var summary: String?

    @Persisted var title: String = ""
}

class imageLinks: EmbeddedObject {
    @Persisted var smallThumbnail: String?

    @Persisted var thumbnail: String?
}

class IndustryIdentifiers: EmbeddedObject {
    @Persisted var identifier: String?

    @Persisted var type: String?
}

class ReadingModes: EmbeddedObject {
    @Persisted var image: Bool?

    @Persisted var text: Bool?
}
