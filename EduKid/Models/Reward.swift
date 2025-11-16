//
//  Reward.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

// MARK: - Reward Model
struct Reward: Identifiable, Codable {
    let id: String
    let name: String
    let cost: Int
    var isClaimed: Bool
    
    init(id: String = UUID().uuidString, name: String, cost: Int, isClaimed: Bool = false) {
        self.id = id
        self.name = name
        self.cost = cost
        self.isClaimed = isClaimed
    }
}
