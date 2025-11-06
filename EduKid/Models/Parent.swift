//
//  Parent.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct parent: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    var children: [Child]
    var totalScore: Int
    let isActive: Bool
}
