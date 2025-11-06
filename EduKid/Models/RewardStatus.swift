//
//  RewardStatus.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
enum RewardStatus: String, Codable {
    case available = "available"
    case claimed = "claimed"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .available: return "Disponible"
        case .claimed: return "Obtenue"
        case .archived: return "Archivée"
        }
    }

    var color: String {
        switch self {
        case .available: return "green"
        case .claimed: return "blue"
        case .archived: return "gray"
        }
    }
}
