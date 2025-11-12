//
//  Reward.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation

struct Reward: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var cost: Int
    var isClaimed: Bool = false
    
    init(id: String = UUID().uuidString, name: String, cost: Int, isClaimed: Bool = false) {
        self.id = id
        self.name = name
        self.cost = cost
        self.isClaimed = isClaimed
    }
}
