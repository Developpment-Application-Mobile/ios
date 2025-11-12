//
//  AddChildView.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//

import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    // États pour le nouvel enfant
    @State private var childName: String = ""
    @State private var childAge: Int = 4 // Minimum 4 ans
    @State private var isShowingPersonalization = false // Pour la navigation
    
    // Note: Pour la photo, on utiliserait un Picker et l'état @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Ajouter un enfant 🚀")
                .font(.custom("Nunito-Bold", size: 30))
                .foregroundColor(Color(hex: "#03045E"))
                .padding(.top, 40)
            
            // Image de profil/Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#CAF0F8"))
                    .frame(width: 120, height: 120)
                
                // Icône de la caméra ou avatar par défaut
                Image(systemName: "camera.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(hex: "#00B4D8"))
            }
            .padding(.vertical, 20)
            
            VStack(spacing: 15) {
                // Champ Nom
                TextField("Prénom de l'enfant", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Sélecteur d'Âge
                HStack {
                    Text("Âge (4-12 ans):")
                        .foregroundColor(Color(hex: "#03045E"))
                    
                    Spacer()
                    
                    Picker("Âge", selection: $childAge) {
                        ForEach(4..<13) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu) // Style compact
                }
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Bouton pour passer à la Personnalisation
            Button("Suivant") {
                // Validation simple
                if !childName.isEmpty {
                    isShowingPersonalization = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#00B4D8"))
            .foregroundColor(.white)
            .font(.system(size: 34, weight: .bold))
            .cornerRadius(12)
            .padding([.horizontal, .bottom])
            .opacity(childName.isEmpty ? 0.6 : 1.0)
            .disabled(childName.isEmpty)
        }
        // Navigation vers l'écran de Personnalisation
        .navigationDestination(isPresented: $isShowingPersonalization) {
            PersonalizationView(
                childName: childName,
                childAge: childAge
            )
        }
    }
}
