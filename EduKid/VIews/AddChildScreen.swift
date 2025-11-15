//
//  AddChildScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import SwiftUI

struct AddChildScreen: View {
    @State private var name = ""
    @State private var age = ""
    @State private var selectedAvatarIndex = 0
    @State private var errorMessage: String?
    @State private var isAddingChild = false  // ← Loader

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    // 42 avatars locaux
    private let avatars: [String] = (1...42).map { "avatar_\($0)" }

    var body: some View {
        ZStack {
            // Fond dégradé radial violet (identique Android)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "AF7EE7").opacity(0.6),
                    Color(hex: "272052")
                ]),
                center: .init(x: 0.15, y: 0.15),
                startRadius: 50,
                endRadius: 600
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header avec bouton retour
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add New Child")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(0.4)
                            Text("Create a profile for your child")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Section Avatar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Avatar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                            ForEach(avatars.indices, id: \.self) { index in
                                AvatarOption(
                                    imageName: avatars[index],
                                    isSelected: selectedAvatarIndex == index
                                ) {
                                    selectedAvatarIndex = index
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(16)
                    }

                    // Champ Nom
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Child's Name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        TextField("Enter child's name", text: $name)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }

                    // Champ Âge
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        TextField("Enter age (1–18)", text: $age)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .onChange(of: age) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if let num = Int(filtered), num >= 1 && num <= 18 {
                                    age = String(num)
                                } else if filtered.isEmpty {
                                    age = ""
                                } else {
                                    age = String(filtered.prefix(2))
                                }
                            }
                    }

                    // Message d’erreur
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(12)
                    }

                    // Bouton ADD CHILD
                    Button("ADD CHILD") {
                        addChild()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "2E2E2E"))
                    .cornerRadius(30)
                    .disabled(isAddingChild || name.trimmingCharacters(in: .whitespaces).isEmpty || age.isEmpty)
                    .overlay {
                        if isAddingChild {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .scaleEffect(0.8)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Add Child (Async + Error Handling)
    private func addChild() {
        guard let ageInt = Int(age),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a valid name and age (1–18)."
            return
        }

        let avatarName = avatars[selectedAvatarIndex]

        Task {
            await MainActor.run { isAddingChild = true }
            defer {
                Task { @MainActor in isAddingChild = false }
            }

            do {
                try await authVM.addChild(name: name, age: ageInt, avatarEmoji: avatarName)
                await MainActor.run {
                    dismiss() // ← Retour seulement si succès
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Avatar Option
struct AvatarOption: View {
    let imageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(8)
                .background(isSelected ? Color(hex: "AF7EE7").opacity(0.2) : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(hex: "AF7EE7") : Color.gray.opacity(0.5),
                                lineWidth: isSelected ? 3 : 1)
                )
        }
    }
}

// MARK: - Preview
struct AddChildScreen_Previews: PreviewProvider {
    static var previews: some View {
        AddChildScreen()
            .environmentObject(AuthViewModel())
    }
}
