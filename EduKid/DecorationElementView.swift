//
//  DecorationElementView.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//

import Foundation
import SwiftUI


struct DecorativeElementsView: View {
    // Les offsets et les tailles sont approximatifs
    
    var body: some View {
        // ZStack permet de superposer et de positionner les éléments avec .offset
        ZStack {
            //
            
            // Book and Globe - Center
            Image(systemName: "globe.americas.fill") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.white.opacity(0.7))
                .offset(y: 100) // Position TopCenter + 79dp

            // Education Book - Top Left
            Image(systemName: "book.closed.fill") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)
                .offset(x: -120, y: -50) // Décalage vers le coin supérieur gauche

            // Coins 1 - Top Right
            Image(systemName: "banknote.fill") // Placeholder pour les pièces
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
                .offset(x: 120, y: -50)

            // Coins 4 - Bottom Left (rotated)
            Image(systemName: "bag.fill.badge.plus") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
                .rotationEffect(.degrees(38.66))
                .offset(x: -80, y: 300)
            
            // Coins 3 - Middle Right (rotated)
            Image(systemName: "bolt.fill") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.cyan)
                .rotationEffect(.degrees(28.68))
                .offset(x: 140, y: 150)
            
            // Book Stacks - Bottom Right (with blur)
            Image(systemName: "books.vertical.fill") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white.opacity(0.3))
                .offset(x: 100, y: 300)
                .blur(radius: 2) // Blur
        }
        .frame(maxWidth: .infinity, maxHeight: 500) // Conteneur pour les éléments décoratifs
    }
}
