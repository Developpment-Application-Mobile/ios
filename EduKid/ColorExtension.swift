//
//  ColorExtension.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
                     .trimmingCharacters(in: .alphanumerics.inverted)
                     .uppercased()
        
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        
        var r: Double = 0, g: Double = 0, b: Double = 0, a: Double = 1.0
        
        switch hex.count {
        case 3: // #RGB
            r = Double((rgb >> 8) & 0xF) * 17 / 255
            g = Double((rgb >> 4) & 0xF) * 17 / 255
            b = Double( rgb       & 0xF) * 17 / 255
            
        case 6: // #RRGGBB
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >>  8) & 0xFF) / 255
            b = Double( rgb        & 0xFF) / 255
            
        case 8: // #RRGGBBAA
            a = Double((rgb >> 24) & 0xFF) / 255
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >>  8) & 0xFF) / 255
            b = Double( rgb        & 0xFF) / 255
            
        default:
            r = 1.0; g = 1.0; b = 1.0 // fallback to white
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
