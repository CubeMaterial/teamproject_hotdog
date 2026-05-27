import Foundation

struct DBAddress: Identifiable, Hashable, Codable {
    let addressSeq: Int
    var id: Int { addressSeq }
}

struct DBApproval: Identifiable, Hashable, Codable {
    let approvalSeq: Int
    var id: Int { approvalSeq }
}

struct DBDog: Identifiable, Hashable, Codable {
    let dogSeq: Int
    var id: Int { dogSeq }
}

struct DBDogAge: Identifiable, Hashable, Codable {
    let dogAgeSeq: Int
    var id: Int { dogAgeSeq }
}

struct DBDogAllergy: Identifiable, Hashable, Codable {
    let dogAllergySeq: Int
    var id: Int { dogAllergySeq }
}

struct DBDogBreeds: Identifiable, Hashable, Codable {
    let dogBreedsSeq: Int
    var id: Int { dogBreedsSeq }
}

struct DBDogColor: Identifiable, Hashable, Codable {
    let dogColorSeq: Int
    var id: Int { dogColorSeq }
}

struct DBDogSize: Identifiable, Hashable, Codable {
    let dogSizeSeq: Int
    var id: Int { dogSizeSeq }
}

struct DBEvent: Identifiable, Hashable, Codable {
    let eventSeq: Int
    var id: Int { eventSeq }
}

struct DBInventory: Identifiable, Hashable, Codable {
    let inventorySeq: Int
    var id: Int { inventorySeq }
}

struct DBMaker: Identifiable, Hashable, Codable {
    let makerSeq: Int
    var id: Int { makerSeq }
}

struct DBProductCategory: Identifiable, Hashable, Codable {
    let productCategorySeq: Int
    var id: Int { productCategorySeq }
}

struct DBProductColor: Identifiable, Hashable, Codable {
    let productColorSeq: Int
    var id: Int { productColorSeq }
}

struct DBProductSubCategory: Identifiable, Hashable, Codable {
    let productSubCategorySeq: Int
    var id: Int { productSubCategorySeq }
}

struct DBReceive: Identifiable, Hashable, Codable {
    let receiveSeq: Int
    var id: Int { receiveSeq }
}

struct DBRefund: Identifiable, Hashable, Codable {
    let refundSeq: Int
    var id: Int { refundSeq }
}

struct DBStaff: Identifiable, Hashable, Codable {
    let staffSeq: Int
    var id: Int { staffSeq }
}

struct DBWarehouse: Identifiable, Hashable, Codable {
    let warehouseSeq: Int
    var id: Int { warehouseSeq }
}

struct DBWarning: Identifiable, Hashable, Codable {
    let warningSeq: Int
    var id: Int { warningSeq }
}
