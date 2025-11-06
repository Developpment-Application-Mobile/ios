import Foundation


struct User: Identifiable, Codable {
    var id: String { _id } 
    let _id: String
    let email: String
    let children: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case _id, email, children, createdAt
    }
}
