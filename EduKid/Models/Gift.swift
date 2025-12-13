import Foundation

struct Gift: Identifiable, Codable {
    let id: String
    let title: String
    let cost: Int
    var purchasedAt: Date? // Optional, present if in inventory

    enum CodingKeys: String, CodingKey {
        case id = "_id" // Map MongoDB _id to id
        case title
        case cost
        case purchasedAt
    }
    
    // Fallback for id if _id is missing (though backend seems to use _id)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try decoding _id first, if not try "id" (in case backend sends different shape in some endpoints), else UUID
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else {
            id = UUID().uuidString
        }
        
        title = try container.decode(String.self, forKey: .title)
        cost = try container.decode(Int.self, forKey: .cost)
        
        // Handle date string decoding if necessary, otherwise assume standard Date decoding
        purchasedAt = try? container.decodeIfPresent(Date.self, forKey: .purchasedAt)
    }
    
    // Default init for creation
    init(id: String = UUID().uuidString, title: String, cost: Int, purchasedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.cost = cost
        self.purchasedAt = purchasedAt
    }
}
