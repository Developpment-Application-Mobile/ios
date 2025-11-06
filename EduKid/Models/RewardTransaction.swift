//
//  RewardTransaction.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation

struct RewardTransaction: Identifiable, Codable {
    var id: String { _id }
    let _id: String
    let childId: String
    let rewardId: String
    let rewardName: String
    let pointsSpent: Int
    let timestamp: Date
}
