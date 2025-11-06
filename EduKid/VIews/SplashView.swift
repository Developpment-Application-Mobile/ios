//
//  SplashView.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//

import SwiftUI

struct SplashView: View {
    // État local pour le logo animé (rotation ou échelle)
    @State private var isActive = false
    @State private var scale = 0.5
    
    var body: some View {
        ZStack {
            // Couleur de fond correspondant à votre palette
            Color(hex:"#03045E").edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("EduKid Quest")
                    .font(.custom("Nunito-Bold", size: 40)) // Assurez-vous d'importer la police
                    .foregroundColor(Color(hex:"#CAF0F8"))
                    .scaleEffect(scale)
                    .animation(.easeOut(duration: 1.5), value: scale)
                
                //  // Remplacer par votre logo réel
            }
        }
        .onAppear {
            withAnimation {
                self.scale = 1.0 // Animation du texte
            }
            
            // Délai de 2 secondes avant de définir isActive à true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
        // Navigation implicite gérée par le conteneur principal
    }
}
