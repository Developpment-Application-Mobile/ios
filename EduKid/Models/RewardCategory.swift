//
//  RewardCategory.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation

enum RewardCategory: String, Codable, CaseIterable {
    case activity = "Activité"
    case treat = "Gourmandise"
    case toy = "Jouet"
    case screenTime = "Temps d'écran"
    case outing = "Sortie"
    case other = "Autre"

    var iconName: String {
        switch self {
        case .activity: return "figure.run"
        case .treat: return "birthday.cake"
        case .toy: return "teddybear"
        case .screenTime: return "tv"
        case .outing: return "map"
        case .other: return "star"
        }
    }
}
